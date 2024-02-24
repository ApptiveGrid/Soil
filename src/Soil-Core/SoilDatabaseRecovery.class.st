Class {
	#name : #SoilDatabaseRecovery,
	#superclass : #Object,
	#instVars : [
		'soil',
		'journal',
		'lsn',
		'beginLSN',
		'postCheckpointLSN'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilDatabaseRecovery >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> readEntryFrom: stream [
	^ [ SoilJournalEntry readFrom: stream ]
		on: MessageNotUnderstood
		do: [ :err | SoilTruncatedRead signal: 'cannot read' ]
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> readFileUpToEnd: aSoilJournalFragmentFile [ 
	| processed entry transactionJournal |
	[ aSoilJournalFragmentFile atEnd ] whileFalse: [ 
		processed := false.
		lsn := aSoilJournalFragmentFile currentLogSequenceNumber.
		entry := self readEntryFrom: aSoilJournalFragmentFile stream.
		(entry class = SoilBeginTransactionEntry) ifTrue: [ 
			processed := true.
			beginLSN := lsn.
			transactionJournal :=  SoilTransactionJournal new index: entry transactionId.
			self readTransactionJournal: transactionJournal from: aSoilJournalFragmentFile stream.
			transactionJournal commitIn: soil ].
		(entry class = SoilCheckpointEntry) ifTrue: [
			processed := true.
			soil control checkpoint: lsn ].
		processed ifFalse: [self halt]]
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> readTransactionJournal: transactionJournal from: stream [ 
	| entry |
	[ stream atEnd ] whileFalse: [  
		entry := self readEntryFrom: stream.
		transactionJournal addEntry: entry.
		(entry class = SoilCommitTransactionEntry) 
			ifTrue: [ ^ transactionJournal ] ].
	Error signal: 'should not reach here'
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> recover [
	| lastCheckpoint lastFileNumber checkpoint fragmentFile |
	"read the log sequence number of the last successful checkpoint from the control 
	file. A successful checkpoint includes writing the transaction logs to disk, 
	commit the contents to the heap, write the checkpoint entry"
	lastCheckpoint := soil control checkpoint.
	fragmentFile := journal openFragmentForLSN: lastCheckpoint.
	"The log sequence number of a successful checkpoint points to the checkpoint 
	entry that was last written"
	checkpoint := SoilJournalEntry readFrom: fragmentFile stream.
	"If the last checkpoint was successful we are at the end of the file and 
	can return because the database is in a sane state"
	fragmentFile atEnd ifTrue: [ ^ self ].
	postCheckpointLSN := fragmentFile currentLogSequenceNumber.
	[ self readFileUpToEnd: fragmentFile ]
		on: SoilTruncatedRead 
		do: [:err | 
			"if a file has been truncated it should be the last fragment file because a database 
			should not proceed if a truncation happened and the next open would have ended right
			at the truncated position"
			(journal lastFileNumber = fragmentFile fileNumber)
				ifFalse: [ SoilDatabaseIsInconsistent signal: 'after a truncated file there should not be another one' ].
			journal 
				currentFragmentFile: fragmentFile;
				cycleFragmentFile ].
	lastFileNumber := journal lastFileNumber.
	lastCheckpoint fileNumber + 1 to: journal lastFileNumber do: [ :fileNumber |
		fragmentFile := journal openFragmentFileNumber: fileNumber.
		self readFileUpToEnd: (journal openFragmentFileNumber: fileNumber) ].
	journal checkpoint.
]

{ #category : #accessing }
SoilDatabaseRecovery >> soil: aSoil [ 
	soil := aSoil
]
