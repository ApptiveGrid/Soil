Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#instVars : [
		'version',
		'journal'
	],
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

{ #category : #committing }
SoilJournalEntry >> commitIn: soil [ 
	self commitIn: soil recovery: false
]

{ #category : #committing }
SoilJournalEntry >> commitIn: soil recovery: aBoolean [
	self subclassResponsibility
]

{ #category : #initialization }
SoilJournalEntry >> initialize [ 
	super initialize.
	version := 1
]

{ #category : #testing }
SoilJournalEntry >> isTransactionEntry [ 
	^ false
]

{ #category : #accessing }
SoilJournalEntry >> journal: anObject [

	journal := anObject
]

{ #category : #testing }
SoilJournalEntry >> providesObjectIds [ 
	^ false
]

{ #category : #'instance creation' }
SoilJournalEntry >> readFrom: aStream [ 
	"skip because the type code is already read"
	version := aStream next  
]

{ #category : #writing }
SoilJournalEntry >> writeOn: aStream [ 
	aStream 
		nextPut: self class journalTypeCode;
		nextPut: version   
]
