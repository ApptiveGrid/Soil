"
The iterator implements all logic related to iteratoring a low level index.

If ""soil"" and ""readVersion"" is set, the iterator restores values using the transaction log, see SoilIndexIterator>>#journalEntriesFor:startingAt:

There are two main clients
- the low level index forwards all methods related to iterating here, not setting the read version
- the SoilIndexedDictionary sets the readVersion (and never uses the index directly)
"
Class {
	#name : #SoilIndexIterator,
	#superclass : #Object,
	#instVars : [
		'index',
		'currentPage',
		'currentKey',
		'nextKey',
		'soil',
		'readVersion'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexIterator class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexIterator
]

{ #category : #'instance creation' }
SoilIndexIterator class >> on: aSoilIndex [
	^ self new 
		index: aSoilIndex 
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject [
	^ self at: aKeyObject ifAbsent: [ KeyNotFound signalFor: aKeyObject in: self  ] 
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject ifAbsent: aBlock [
	| foundValue |
	foundValue := self find: aKeyObject ifAbsent: aBlock.
 	^(self restoreValue: foundValue forKey: currentKey) ifNil: [ aBlock value ]
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject put: anObject [
	^ self 
		basicAt: (index indexKey: aKeyObject) 
		put: anObject
]

{ #category : #accessing }
SoilIndexIterator >> atIndex: anInteger [
	| current |
	current := self first.
	2 to: anInteger do: [ :idx |
		current := self next ].
	^ current value
]

{ #category : #enumerating }
SoilIndexIterator >> basicAssociationsDo: aBlock [
	| item |
	[ (item := self basicNextAssociation ) notNil ] whileTrue: [ 
 		aBlock value: item ] 
]

{ #category : #accessing }
SoilIndexIterator >> basicAt: indexKey put: anObject [
	self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> basicNextAssociation [
	| item |
	"preliminary support for nextKey. This is useful when iterating via #next 
	in order not jump over the first search key. nextKey implies the currentPage
	is on the right spot"
	nextKey ifNotNil: [ 
		item := currentPage 
			itemAt: nextKey 
			ifAbsent: [ Error signal: 'shoulndt be possible' ].
		nextKey := nil.
		^ item ].
	currentPage ifNil: [ 
		currentPage := index store headerPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemAfter: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						(currentPage next = 0) ifTrue: [ ^ nil ].
						currentPage := index store pageAt: currentPage next.
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilIndexIterator >> currentPage [

	^ currentPage
]

{ #category : #accessing }
SoilIndexIterator >> currentPage: anObject [

	currentPage := anObject
]

{ #category : #enumerating }
SoilIndexIterator >> do: aBlock [
	| item |
	"We use basicNextAssociation to avoid the creation of intermediate associations of nextAssociation"
	[ (item := self basicNextAssociation ) notNil ] whileTrue: [ 
 				(self
 					 restoreValue: item value
 					 forKey: item key) ifNotNil: [:notNil | aBlock value: notNil ]]
]

{ #category : #private }
SoilIndexIterator >> find: key [
	^ self find: key ifAbsent: [ ]
]

{ #category : #private }
SoilIndexIterator >> find: key ifAbsent: aBlock [
	currentKey := index indexKey: key.
	self findPageFor: currentKey.
	^ currentPage valueAt: currentKey ifAbsent: aBlock
]

{ #category : #private }
SoilIndexIterator >> findPageFor: indexKey [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> first [
	^ self firstAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> first: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	anInteger timesRepeat: [
		| next |
		next := self next ifNil: [ ^ result].
		result add: next ].
	^ result
]

{ #category : #accessing }
SoilIndexIterator >> firstAssociation [ 
	"Note: key will be index key"
	| item |
	currentPage := index store headerPage.
	item := self nextAssociation.
	currentKey := item 
		ifNotNil: [ item key ].
	^ item
]

{ #category : #private }
SoilIndexIterator >> historicValueAt: key ifAbsent: absentBlock [
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
 					ifNotEmpty: [:entries | entries last oldValue ]
 					ifEmpty: absentBlock]
]

{ #category : #accessing }
SoilIndexIterator >> index [
	^index
]

{ #category : #accessing }
SoilIndexIterator >> index: anIndex [ 
	index := anIndex
]

{ #category : #testing }
SoilIndexIterator >> isEmpty [
 
	^ index isEmpty or: [  
		self currentPage: index firstPage.
		"all items might be removed and not restorable"
 		self index firstPage items allSatisfy: [ :each |
 		  	(self restoreValue: each value forKey: each key) isNil ]]
]

{ #category : #private }
SoilIndexIterator >> journalEntriesFor: key startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId >  readVersion ] whileTrue: [  
		(soil journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class = SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
				(each key = key) ifTrue: [ 
					entries add: each ] ]  ].
		transactionId := transactionId - 1.
	].
   ^ entries
]

{ #category : #accessing }
SoilIndexIterator >> last [
	^ self lastAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> lastAssociation [
	"Note: key will be index key"
	| lastAssociation lastValue key |
	lastAssociation := self priorAssociation ifNil: [ ^nil ].
	lastValue := (self
 			restoreValue: lastAssociation value
 			forKey: (key := lastAssociation key)).
	^ lastValue ifNil: [ self priorAssociation ] ifNotNil: [ key -> lastValue ]
]

{ #category : #accessing }
SoilIndexIterator >> lastPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> next [
	^ self nextAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> next: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	anInteger timesRepeat: [
		| next |
		next := self next ifNil: [ ^ result].
		result add: next ].
	^ result
]

{ #category : #accessing }
SoilIndexIterator >> nextAfter: key [
	^ (self nextAssociationAfter: key) value
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociation [
	"Note: key will be index key"
	| nextAssociation nextValue key |
	nextAssociation := self basicNextAssociation ifNil: [ ^nil ].
	nextValue := (self
 			restoreValue: nextAssociation value
 			forKey: (key := nextAssociation key)).
	^ nextValue ifNil: [ self nextAssociation ] ifNotNil: [ key -> nextValue ]
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociationAfter: key [
	"Note: key will be index key"
	self find: key.
	^ self nextAssociation
]

{ #category : #private }
SoilIndexIterator >> nextCloseTo: key [
	"return the next entry after key, even if key itself is not there"
	^ self at: (self nextKeyCloseTo: key)
]

{ #category : #private }
SoilIndexIterator >> nextKeyCloseTo: key [
	"Note: returnrd key will be an index key"
	| indexKey |
	indexKey := index indexKey: key.
	self findPageFor: indexKey.
	nextKey := currentPage keyOrClosestAfter: indexKey.
	^ nextKey
		ifNil: [ "if there is no close key found, we position the cursor at the end, so that asking for the next association will return nil" 
			currentKey := currentPage lastKey ]
		ifNotNil: [ 
			"if there is a close key found, we make sure the cursor get properly positioned"
			currentKey := nextKey ]
]

{ #category : #accessing }
SoilIndexIterator >> pageAt: anInteger [
	^ index store pageAt: anInteger
]

{ #category : #private }
SoilIndexIterator >> priorAssociation [
	| item |
	"Find the association before, if currentPage is not set we return the last association"
	currentPage ifNil: [ 
		currentPage := index lastPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemBefore: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						(currentPage next = 0) ifTrue: [ ^ nil ].
						currentPage := index store pageAt: currentPage priorPage.
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage lastItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilIndexIterator >> readVersion [

	^ readVersion
]

{ #category : #accessing }
SoilIndexIterator >> readVersion: anObject [

	readVersion := anObject
]

{ #category : #removing }
SoilIndexIterator >> removeKey: key [ 
	^ self 
		at: key 
		put: SoilObjectId removed
]

{ #category : #private }
SoilIndexIterator >> restoreValue: value forKey: key [
	"restore a value that has been removed by a later transaction"
	^ value isRemoved 
		ifTrue: [
			self 
				historicValueAt: key 
				ifAbsent: [ nil ] ]
		ifFalse: [
			"restore a value that has been overwritten by a later transaction"   
			self 
				historicValueAt: key 
				ifAbsent: [ value ] ]
]

{ #category : #accessing }
SoilIndexIterator >> size [
	"We iterate over all elements to get the size. Slow!"
	| sum |
	sum := 0.
	self do: [ :each | sum := sum + 1 ].
	^ sum
]

{ #category : #accessing }
SoilIndexIterator >> soil [

	^ soil
]

{ #category : #accessing }
SoilIndexIterator >> soil: anObject [

	soil := anObject
]

{ #category : #transactions }
SoilIndexIterator >> updateCurrentTransaction: anInteger [ 
	currentPage lastTransaction: anInteger
]

{ #category : #enumerating }
SoilIndexIterator >> values [ 
	| values |
	values := OrderedCollection new.
	self do: [ :each |
		values add: each value ].
	^ values
]
