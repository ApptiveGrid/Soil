"
The iterator implements all logic related to iteratoring a low level index.

If ""soil"" and ""readVersion"" is set, the iterator restores values using the transaction log, see SoilIndexIterator>>#journalEntriesFor:startingAt:

There are two main clients
- the low level index forwards all methods related to iterating here, not setting the read version
- the SoilIndexedDictionary sets the readVersion (and never uses the index directly)
"
Class {
	#name : #SoilRestoringIndexIterator,
	#superclass : #SoilIndexIterator,
	#instVars : [
		'readVersion',
		'journal'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilRestoringIndexIterator class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilRestoringIndexIterator
]

{ #category : #'instance creation' }
SoilRestoringIndexIterator class >> on: aSoilIndex [
	^ self new 
		index: aSoilIndex 
]

{ #category : #private }
SoilRestoringIndexIterator >> historicValueAt: key ifAbsent: absentBlock [
 	"a removed value will return ObjectId 0:0"
 	readVersion ifNil: [ ^ absentBlock value ].
 	^ (self currentPage isOlderThan: readVersion) 
 		ifTrue: [ 
 			"all modifications to this page have been done before we
 			started the transaction, so the removal is visibile and 
 			value absent"
 			   absentBlock value ] 
 		ifFalse: [
 			"we determine all changes between our transaction and the
 			last one modifying the page. if we get back changes for the
 			key the value of the oldes entry has the value it had before"
 			(self 
 				journalEntriesFor: key 
 				startingAt: self currentPage lastTransaction)
 					ifNotEmpty: [:entries | 
						entries last oldValue ifNotNil: [ :old | key -> old ] ]
 					ifEmpty: absentBlock]
]

{ #category : #private }
SoilRestoringIndexIterator >> historicValueAt: key value: value ifAbsent: absentBlock [
 	"a removed value will return ObjectId 0:0"
 	readVersion ifNil: [ ^ absentBlock value ].
 	^ (self currentPage isOlderThan: readVersion) 
 		ifTrue: [ 
 			"all modifications to this page have been done before we
 			started the transaction, so the removal is visibile and 
 			value absent"
 			   absentBlock value ] 
 		ifFalse: [ | journalEntries |
 			"we determine all changes between our transaction and the
 			last one modifying the page. if we get back changes for the
 			key the value of the oldes entry has the value it had before"
			journalEntries := index uniqueKeys 
				ifTrue: [ self 
 					journalEntriesFor: key
 					startingAt: self currentPage lastTransaction ]
				ifFalse: [ self 
 					journalEntriesFor: key value: value
 					startingAt: self currentPage lastTransaction ].
			
 			journalEntries
 					ifNotEmpty: [:entries | key -> entries last oldValue]
 					ifEmpty: absentBlock]
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journalEntriesFor: key startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId > readVersion ] whileTrue: [  
		(journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class == SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
				(each key = key) ifTrue: [ 
					entries add: each ] ]  ].
		transactionId := transactionId - 1.
	].
   ^ entries
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journalEntriesFor: key value: value startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId > readVersion ] whileTrue: [  
		(journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class == SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
			(each isForItem: key -> value) ifTrue: [ 
					entries add: each ] ]  ].
		transactionId := transactionId - 1.
	].
   ^ entries
]

{ #category : #accessing }
SoilRestoringIndexIterator >> readVersion: anInteger [ 
	readVersion := anInteger
]

{ #category : #private }
SoilRestoringIndexIterator >> restoreItem: item [ 
	"restore a value that has been removed by a later transaction"
	| newItem |
	item ifNil: [ ^ nil ].
	"restore a value that has been overwritten by a later transaction" 
	newItem :=  self 
				historicValueAt: item key
				value: item value
				ifAbsent: [ item ].
	^ newItem 
		ifNotNil: [
			newItem value ifNotNil: [:it| it isRemoved ifTrue: [ ^nil ]].
			item key -> newItem value ]
]

{ #category : #strategy }
SoilRestoringIndexIterator >> returnObjectId [
	itemStrategy := SoilObjectIdValueStrategy new
]

{ #category : #strategy }
SoilRestoringIndexIterator >> returnProxyForTransaction: aSoilTransaction [ 
	itemStrategy := SoilProxyValueStrategy new 
		objectRepository: aSoilTransaction;
		yourself
]
