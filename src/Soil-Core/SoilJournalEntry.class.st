Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#category : #'Soil-Core-Journal'
}

{ #category : #api }
SoilJournalEntry class >> allMapped [ 
	| map |
	map := Dictionary new.
	(self allSubclasses reject: #isAbstract) do: [ :cls | 
		 map 
			at: cls journalTypeCode 
			put: cls ].
	^ map
]

{ #category : #testing }
SoilJournalEntry class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilJournalEntry
]

{ #category : #'instance creation' }
SoilJournalEntry class >> readFrom: aStream [ 
	^ (self withTypeCode: aStream next asInteger) new 
		readFrom: aStream;
		yourself
]

{ #category : #'instance creation' }
SoilJournalEntry class >> withTypeCode: anInteger [ 
	^ (self allSubclasses reject: #isAbstract)
		detect: [ :each | each journalTypeCode = anInteger ]
		ifNone: [ Error signal: 'cannot find class for journal type code ', anInteger asString ]
]

{ #category : #testing }
SoilJournalEntry >> isTransactionEntry [ 
	^ false
]

{ #category : #'instance creation' }
SoilJournalEntry >> readFrom: aStream [ 
	"skip because the type code is already read"
	
	"as no journal entry starts with a zero byte at second position
	we can introduce a version number of 0. Legacy format is detectable
	at non-zero value. If the value is zero we skip it because it means
	the entry is a new one.
	Before this hack is being removed and the version bumped we need to 
	be sure there are no legacy journals lying around"
	(aStream peek = 0) ifTrue: [ aStream next ] ifFalse: [ self halt ] 

]

{ #category : #writing }
SoilJournalEntry >> writeOn: aStream [ 
	aStream 
		nextPut: self class journalTypeCode;
		nextPut: 0 "placeholder for future version byte"
]
