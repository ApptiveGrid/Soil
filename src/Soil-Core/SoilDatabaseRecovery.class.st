Class {
	#name : #SoilDatabaseRecovery,
	#superclass : #Object,
	#instVars : [
		'soil',
		'journal',
		'lsn'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #accessing }
SoilDatabaseRecovery >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #private }
SoilDatabaseRecovery >> readEntryFrom: stream [
	^ [ SoilJournalEntry readFrom: stream ]
		on: MessageNotUnderstood
		do: [ :err | SoilTruncatedRead signal: 'cannot read' ]
]

{ #category : #private }
SoilDatabaseRecovery >> readFragmentFile: aSoilJournalFragmentFile [ 
	| processed entry transactionJournal |
	[ aSoilJournalFragmentFile atEnd ] whileFalse: [ 
		processed := false.
		"remember the position before reading the next entry"
		lsn := aSoilJournalFragmentFile currentLogSequenceNumber.
		entry := self readEntryFrom: aSoilJournalFragmentFile stream.
		"if we read a begin entry we can read a transaction journal"
		(entry class = SoilBeginTransactionEntry) ifTrue: [ 
			processed := true.
			transactionJournal :=  SoilTransactionJournal new index: entry transactionId.
			"transaction journals are written always completely so we can read until we 
			discover a commit entry. "
			self readTransactionJournal: transactionJournal from: aSoilJournalFragmentFile stream.
			transactionJournal commitIn: soil recovery: true ].
		"reading a checkpoint entry is unlikely. It should be possible only if there was an 
		error after writing the checkpoint entry and before marking that position in the control
		file. But it is possible it happens so we just need to complete it by updating the 
		checkpoint position in the control file"
		(entry class = SoilCheckpointEntry) ifTrue: [
			processed := true.
			soil control checkpoint: lsn ].
		processed ifFalse: [
			"it is unlikely we end up here. It means we could read a journal entry from the stream
			but it none of the expected ones."
			Error signal: 'unknown journal entry discovered' ] ]
]

{ #category : #private }
SoilDatabaseRecovery >> readFragmentFileProtected: aSoilFragmentFile [
	[ self readFragmentFile: aSoilFragmentFile ]
		on: SoilTruncatedRead 
		do: [:err | 
			"a file that has been truncated should be the last fragment file because a database 
			should not proceed if a truncation happens and the next open would have ended right
			at the truncated position"
			(journal lastFileNumber = aSoilFragmentFile fileNumber)
				ifFalse: [ SoilDatabaseIsInconsistent signal: 'after a truncated file there should not be another one' ].
			"we currently have no way of reading behind a truncated piece of a fragment. We cycle
			the fragment file in order to write new entries to a new file. Future reads can just 
			skip a fragment file on truncated reads"
			journal 
				currentFragmentFile: aSoilFragmentFile;
				cycleFragmentFile ]
]

{ #category : #private }
SoilDatabaseRecovery >> readTransactionJournal: transactionJournal from: stream [ 
	| entry |
	"read the transaction journal until a commit entry is read"
	[ stream atEnd ] whileFalse: [  
		entry := self readEntryFrom: stream.
		transactionJournal addEntry: entry.
		(entry class = SoilCommitTransactionEntry) 
			ifTrue: [ ^ transactionJournal ] ].
	SoilTruncatedRead signal: 'reading of transaction journal is incomplete'
]

{ #category : #api }
SoilDatabaseRecovery >> recover [
	| lastCheckpoint checkpointEntry fragmentFile |
	"read the log sequence number of the last successful checkpoint from the control 
	file. A successful checkpoint includes writing the transaction logs to disk, 
	commit the contents to the heap, write the checkpoint entry"
	lastCheckpoint := soil control lastCheckpoint.
	"in case the fragment file is missing we restart the journal from the next 
	fragment file id. 
	NOTE: This is a deliberate emergency handler at the moment. In case of very strange
	filesystem inconsistency we can continue to use the database with the last checkpointed
	state. This may become a configuration option later"
	(journal existsFragmentFileForLSN: lastCheckpoint) ifFalse: [ 
		journal cycleFragmentFile.
		soil checkpoint.
		^ self ].
	fragmentFile := journal openFragmentForLSN: lastCheckpoint.
	"The log sequence number of a successful checkpoint points to the checkpoint 
	entry that was last written"
	checkpointEntry := [ SoilJournalEntry readFrom: fragmentFile stream ]
		on: Error 
		do: [ :error | 
			"in case of a bogus checkpoint position we cannot recover the file but 
			create a new one and continue"
			journal 
				currentFragmentFile: fragmentFile;
				cycleFragmentFile.
			soil checkpoint.
			^ self ].
	"If the last checkpoint was successful we are at the end of the file and 
	can return because the database is in a sane state"
	fragmentFile atEnd ifTrue: [ ^ self ].
	
	"the fragment file contains more entries after the last checkpoint. Read the
	current fragment file to its end and apply all transaction logs/checkpoints found"
	self readFragmentFileProtected: fragmentFile.
	
	"it is possible there are more fragment files after that of the last checkpoint.
	This is due to multiple transactions have been written to the journal and there
	was a size overflow. Or it happens because the prior step did experience a 
	truncated read and cycled the fragment file"
	lastCheckpoint fileNumber + 1 to: journal lastFileNumber do: [ :fileNumber |
		fragmentFile := journal openFragmentFileNumber: fileNumber.
		fragmentFile setToStart.
		self readFragmentFileProtected: fragmentFile ].
	
	"we end up here because the journal needed to be recovered. We create new checkpoint
	to mark that we covered about the extra entries or bogus data so future reads can
	proceed from here"
	soil checkpoint.
]

{ #category : #accessing }
SoilDatabaseRecovery >> soil: aSoil [ 
	soil := aSoil
]
