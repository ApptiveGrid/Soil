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
SoilRestoringIndexIterator >> historicValueFor: item [
 	"a removed value will return item with value ObjectId 0:0"
	 | journalEntries |
 	readVersion ifNil: [ ^ item ].
 	(self currentPage isOlderThan: readVersion) ifTrue: [ 
 			"all modifications to this page have been done before we
 			started the transaction, so the removal is visibile and 
 			value absent"
 			  ^  item ].

 	"we determine all changes between our transaction and the
 	last one modifying the page. if we get back changes for the
 	key the value of the oldes entry has the value it had before"
	journalEntries := self 
 			journalEntriesFor: item
 			startingAt: self currentPage lastTransaction.
			
 	journalEntries ifEmpty: [^ item].
	^ item key -> journalEntries last oldValue
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journalEntriesFor: item startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId > readVersion ] whileTrue: [  
		(journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class == SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
			(each isForItem: item) ifTrue: [ 
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
	"restore a value that has been removed by a later transaction
	this method just wraps historicValueFor: and turns removed items into nil"
	| newItem |
	
	newItem := self historicValueFor: item.
	newItem ifNotNil: [
			newItem value ifNotNil: [:it| it isRemoved ifTrue: [ ^ nil ]]].
	^newItem
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
