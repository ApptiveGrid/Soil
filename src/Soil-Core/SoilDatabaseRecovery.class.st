Class {
	#name : #SoilDatabaseRecovery,
	#superclass : #Object,
	#instVars : [
		'soil',
		'journal'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilDatabaseRecovery >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #'as yet unclassified' }
SoilDatabaseRecovery >> recover [
	| lastCheckpoint fragmentFiles checkpointFilename file lastFileNumber checkpoint tj ch |
	lastCheckpoint := soil control checkpoint.
	fragmentFiles := journal fragmentFiles last.
	checkpointFilename := journal filenameFrom: lastCheckpoint fileNumber.
	file := journal openFragmentFile: checkpointFilename.
	(file size > lastCheckpoint fileOffset) 
		ifTrue: [ 
			file stream position: lastCheckpoint fileOffset.
			checkpoint := SoilJournalEntry readFrom: file stream.
			file atEnd 
				ifTrue: [ ^ self "can it be that it is at the end of this file but there are more files?"]
				ifFalse: [  
					tj := SoilTransactionJournal readFrom: file stream.
					ch := SoilJournalEntry readFrom: file stream.
					self halt.] ]
		ifFalse: [ 
			lastFileNumber := journal fileNumberFrom: fragmentFiles basename.
			(lastFileNumber > lastCheckpoint fileNumber) ifTrue: [ 
				self halt ]  ] .
	self halt.	
	
]

{ #category : #accessing }
SoilDatabaseRecovery >> soil: aSoil [ 
	soil := aSoil
]
