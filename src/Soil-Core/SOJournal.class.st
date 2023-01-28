Class {
	#name : #SOJournal,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'stream',
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SOJournal >> addEntry: aJournalEntry [
	entries add: aJournalEntry 
]

{ #category : #accessing }
SOJournal >> commit [
	self write.
	entries do: [ :each | each commitIn: transaction ]
]

{ #category : #'instance creation' }
SOJournal >> create [
	stream := self path 
		deleteIfAbsent: []; 
		ensureCreateFile;
		binaryWriteStream 
]

{ #category : #initialization }
SOJournal >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #accessing }
SOJournal >> path [
	^ self soil path / #journal / transaction writeVersion asString , #journal
]

{ #category : #accessing }
SOJournal >> soil [
	^ transaction soil
]

{ #category : #accessing }
SOJournal >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]

{ #category : #writing }
SOJournal >> write [ 
	entries do: [ :each | each writeOn: stream ].
	stream 
		flush
]
