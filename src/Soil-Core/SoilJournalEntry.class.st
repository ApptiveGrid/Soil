Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#category : #'Soil-Core-Journal'
}

{ #category : #'as yet unclassified' }
SoilJournalEntry class >> withTypeCode: anInteger [ 
	^ self allSubclasses 
		detect: [ :each | each journalTypeCode = anInteger ]
		ifNone: [ Error signal: 'cannot find class for journal type code ', anInteger asString ]
]

{ #category : #writing }
SoilJournalEntry >> readFrom: aStream [ 
	"skip because the type code is already read"
]

{ #category : #writing }
SoilJournalEntry >> writeOn: aStream [ 
	aStream nextPut: self class journalTypeCode
	
]
