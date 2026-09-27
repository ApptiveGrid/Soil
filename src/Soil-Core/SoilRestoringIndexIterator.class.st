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
	"the item as it was at readVersion. The journal entries between the last transaction
	that modified the page and readVersion are followed from the newest to the oldest:
	each one that produced the value we hold says in its oldValue what the key held
	before, so a key overwritten twice after readVersion goes back two steps and not one.
	A key that did not exist at readVersion ends with the value nil, a removed one with
	the removed marker.

	A transaction journal that is neither in memory nor in a fragment file any more -
	the oldest fragment files are deleted - leaves nothing to go back with, and the
	item is taken as it is now"
	| restored |
	readVersion ifNil: [ ^ item ].
	(self currentPage isOlderThan: readVersion) ifTrue: [
		"all modifications to this page have been done before we
		started the transaction, so the removal is visibile and
		value absent"
		^ item ].
	restored := item.
	self currentPage lastTransaction to: readVersion + 1 by: -1 do: [ :transactionId |
		(journal transactionJournalAt: transactionId ifAbsent: [ ^ item ]) entries reverseDo: [ :each |
			restored value ifNil: [ ^ restored ].
			((each class == SoilAddKeyEntry or: [ each class == SoilRemoveKeyEntry ])
				and: [ each isForItem: restored index: index id ]) ifTrue: [
					restored := restored key -> each oldValue ] ] ].
	^ restored
]

{ #category : #accessing }
SoilRestoringIndexIterator >> journal: aSoilPersistentDatabaseJournal [ 
	journal := aSoilPersistentDatabaseJournal 
]

{ #category : #accessing }
SoilRestoringIndexIterator >> readVersion: anInteger [ 
	readVersion := anInteger
]

{ #category : #private }
SoilRestoringIndexIterator >> restoreItem: item [
	"the item as it was at readVersion, nil if the key was removed by then or did not
	exist yet. The latter comes back from historicValueFor: with the value nil, and
	handed on as it is an iterator ends early at it or answers an association to nothing"
	| newItem |
	newItem := self historicValueFor: item.
	newItem ifNil: [ ^ nil ].
	newItem value ifNil: [ ^ nil ].
	newItem value isRemoved ifTrue: [ ^ nil ].
	^ newItem
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
