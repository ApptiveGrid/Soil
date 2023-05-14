Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'stream',
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilJournal class >> soilTransientInstVars [ 
	^ #( transaction )
]

{ #category : #adding }
SoilJournal >> addEntries: aCollection [ 
	aCollection do: [ :each | self addEntry: each ]
]

{ #category : #adding }
SoilJournal >> addEntry: aJournalEntry [
	entries add: aJournalEntry 
]

{ #category : #'initialize-release' }
SoilJournal >> close [ 
	stream ifNotNil: [ stream close ]
]

{ #category : #accessing }
SoilJournal >> commit [
	entries do: [ :each | each commitIn: transaction ]
]

{ #category : #'instance creation' }
SoilJournal >> create [
	stream := self path 
		deleteIfAbsent: []; 
		ensureCreateFile;
		binaryWriteStream 
]

{ #category : #accessing }
SoilJournal >> entries [
	^ entries
]

{ #category : #accessing }
SoilJournal >> entryAt: anInteger [ 
	^ entries at: anInteger 
]

{ #category : #initialization }
SoilJournal >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #accessing }
SoilJournal >> path [
	^ self soil path / #journal / transaction writeVersion asString , #journal
]

{ #category : #accessing }
SoilJournal >> size [ 
	^ entries size
]

{ #category : #accessing }
SoilJournal >> soil [
	^ transaction soil
]

{ #category : #accessing }
SoilJournal >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]

{ #category : #writing }
SoilJournal >> write [ 
	entries do: [ :each | each writeOn: stream ].
	stream 
		flush
]
