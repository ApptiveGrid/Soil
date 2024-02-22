Class {
	#name : #SoilDatabaseRecovery,
	#superclass : #Object,
	#instVars : [
		'soil',
		'journal',
		'file'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilDatabaseRecovery >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> readFileUpToEnd: aSoilJournalFragmentFile [ 
	| processed entry transactionJournal lsn |
	[ aSoilJournalFragmentFile atEnd ] whileFalse: [ 
		processed := false.
		lsn := aSoilJournalFragmentFile currentLogSequenceNumber.
		entry := SoilJournalEntry readFrom: aSoilJournalFragmentFile stream.
		(entry class = SoilBeginTransactionEntry) ifTrue: [ 
			processed := true.
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
		entry := SoilJournalEntry readFrom: stream.
		transactionJournal addEntry: entry.
		(entry class = SoilCommitTransactionEntry) 
			ifTrue: [ ^ transactionJournal ] ].
	Error signal: 'should not reach here'
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> recover [
	| lastCheckpoint lastFileNumber checkpoint |

	lastCheckpoint := soil control checkpoint.
	file := journal openFragmentForLSN: lastCheckpoint.
	checkpoint := SoilJournalEntry readFrom: file stream.
	self readFileUpToEnd: file.
	lastFileNumber := journal lastFileNumber.
	lastCheckpoint fileNumber + 1 to: journal lastFileNumber do: [ :fileNumber |
		file := journal openFragmentFileNumber: fileNumber.
		self readFileUpToEnd: (journal openFragmentFileNumber: fileNumber) ].
	journal checkpoint.
]

{ #category : #accessing }
SoilDatabaseRecovery >> soil: aSoil [ 
	soil := aSoil
]
