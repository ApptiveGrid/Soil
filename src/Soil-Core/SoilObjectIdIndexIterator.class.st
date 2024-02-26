"
The iterator implements all logic related to iteratoring a low level index.

If ""soil"" and ""readVersion"" is set, the iterator restores values using the transaction log, see SoilIndexIterator>>#journalEntriesFor:startingAt:

There are two main clients
- the low level index forwards all methods related to iterating here, not setting the read version
- the SoilIndexedDictionary sets the readVersion (and never uses the index directly)
"
Class {
	#name : #SoilObjectIdIndexIterator,
	#superclass : #SoilIndexIterator,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilObjectIdIndexIterator class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilObjectIdIndexIterator
]

{ #category : #'instance creation' }
SoilObjectIdIndexIterator class >> on: aSoilIndex [
	^ self new 
		index: aSoilIndex 
]

{ #category : #private }
SoilObjectIdIndexIterator >> convertItemX: item [
	"restore a value that has been removed by a later transaction"
	| newItem |
	newItem :=  item value isRemoved 
		ifTrue: [
			self 
				historicValueAt: item key 
				ifAbsent: [ nil ] ]
		ifFalse: [
			"restore a value that has been overwritten by a later transaction"   
			self 
				historicValueAt: item key 
				ifAbsent: [ item ] ].
	^ newItem value 
		ifNotNil: [ super convertItem: newItem ]
		ifNil: [ newItem ]
]

{ #category : #'as yet unclassified' }
SoilObjectIdIndexIterator >> returnObjectId [
	itemStrategy := SoilObjectIdItemStrategy new
]

{ #category : #'as yet unclassified' }
SoilObjectIdIndexIterator >> returnProxyIn: aSoilTransaction [ 
	itemStrategy := SoilProxyItemStrategy new 
		iterator: self;
		transaction: aSoilTransaction;
		yourself
]

{ #category : #transactions }
SoilObjectIdIndexIterator >> updateCurrentTransaction: anInteger [ 
	currentPage lastTransaction: anInteger
]
