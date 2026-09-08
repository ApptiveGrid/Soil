Class {
	#name : #SoilDatabaseRecovery,
	#superclass : #Object,
	#instVars : [
		'soil',
		'journal',
		'lsn',
		'replayedTransactions'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #private }
SoilDatabaseRecovery >> count: anInteger of: aNoun [
	"so that a report says '1 transaction' and not '1 transactions'"
	^ anInteger printString, ' ', (anInteger = 1 ifTrue: [ aNoun ] ifFalse: [ aNoun, 's' ])
]

{ #category : #testing }
SoilDatabaseRecovery >> isNeeded [
	"Whether there is anything past the last checkpoint to replay. Reads only, and
	through the streams the database was opened with, so this can be asked of a
	database lying on read-only media."

	| lastCheckpoint fragmentFile |
	lastCheckpoint := soil control lastCheckpoint.
	(journal existsFragmentFileForLSN: lastCheckpoint) ifFalse: [ ^ true ].
	fragmentFile := journal openFragmentForLSN: lastCheckpoint.
	^ [ [ SoilJournalEntry readFrom: fragmentFile stream ]
			on: Error
			do: [ :error | ^ true ].
		fragmentFile atEnd not ]
			ensure: [ fragmentFile close ]
]

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
		(entry class == SoilBeginTransactionEntry) ifTrue: [ 
			processed := true.
			transactionJournal :=  SoilTransactionJournal new index: entry transactionId.
			"transaction journals are written always completely so we can read until we 
			discover a commit entry. "
			self readTransactionJournal: transactionJournal from: aSoilJournalFragmentFile stream.
			transactionJournal commitIn: soil recovery: true.
			replayedTransactions ifNotNil: [ replayedTransactions := replayedTransactions + 1 ] ].
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
			journal cycleFragmentFileAfter: aSoilFragmentFile ]
]

{ #category : #private }
SoilDatabaseRecovery >> readTransactionJournal: transactionJournal from: stream [ 
	| entry |
	"read the transaction journal until a commit entry is read"
	[ stream atEnd ] whileFalse: [  
		entry := self readEntryFrom: stream.
		transactionJournal addEntry: entry.
		(entry class == SoilCommitTransactionEntry) 
			ifTrue: [ ^ transactionJournal ] ].
	SoilTruncatedRead signal: 'reading of transaction journal is incomplete'
]

{ #category : #api }
SoilDatabaseRecovery >> recover [
	| lastCheckpoint checkpointEntry fragmentFile |
	"nothing past the last checkpoint means nothing to do, and nothing to write"
	self isNeeded ifFalse: [
		soil emit: 'recovery: nothing past the last checkpoint'.
		^ self ].
	"from here on recovery writes - the heap, the control file, sometimes a fresh
	fragment file. Refusing here rather than failing inside one of those writes is
	what lets a database on read-only media be opened at all: the reader learns that
	the state is not readable as it stands, and can repair a copy it may write to."
	soil canRecover ifFalse: [
		soil emit: 'recovery: needed, but this image may not write to the database'.
		SoilDatabaseNeedsRecovery new
			soil: soil;
			signal ].
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
		soil emit: 'recovery: the fragment file for the last checkpoint ',
			lastCheckpoint printString, ' is missing - starting a new one and checkpointing'.
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
			soil emit: 'recovery: the last checkpoint position ', lastCheckpoint printString,
				' does not read back (', error messageText,
				') - starting a new fragment file and checkpointing'.
			journal cycleFragmentFileAfter: fragmentFile.
			soil checkpoint.
			^ self ].
	"If the last checkpoint was successful we are at the end of the file and
	can return because the database is in a sane state. Close the read-only
	recovery handle so the journal can later open the file for writing (a second
	open in write mode while this one is still open fails on Windows)"
	fragmentFile atEnd ifTrue: [
		soil emit: 'recovery: nothing to replay, the last checkpoint ',
			lastCheckpoint printString, ' ends the journal'.
		fragmentFile close.
		^ self ].
	
	"the fragment file contains more entries after the last checkpoint. Read the
	current fragment file to its end and apply all transaction logs/checkpoints found"
	soil emit: 'recovery: replaying the journal from the last checkpoint ',
		lastCheckpoint printString.
	replayedTransactions := 0.
	self readFragmentFileProtected: fragmentFile.
	fragmentFile close.
	
	"it is possible there are more fragment files after that of the last checkpoint.
	This is due to multiple transactions have been written to the journal and there
	was a size overflow. Or it happens because the prior step did experience a 
	truncated read and cycled the fragment file"
	lastCheckpoint fileNumber + 1 to: journal lastFileNumber do: [ :fileNumber |
		fragmentFile := journal openFragmentFileNumber: fileNumber.
		fragmentFile setToStart.
		self readFragmentFileProtected: fragmentFile.
		fragmentFile close ].
	
	"we end up here because the journal needed to be recovered. We create new checkpoint
	to mark that we covered about the extra entries or bogus data so future reads can
	proceed from here"
	soil checkpoint.
	soil emit: 'recovery: replayed ',
		(self count: replayedTransactions of: 'transaction'), ' from ',
		(self count: journal lastFileNumber - lastCheckpoint fileNumber + 1 of: 'fragment file'),
		', checkpointed'
]

{ #category : #accessing }
SoilDatabaseRecovery >> soil: aSoil [ 
	soil := aSoil
]
