"
Logs removal of a key (or key-value in multikey mode).

Removal is Logged by the indexed dictionary when overriding an entry with a SoilRemovedID.
"
Class {
	#name : #SoilRemoveKeyEntry,
	#superclass : #SoilIndexJournalEntry,
	#instVars : [
		'key',
		'oldValue'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilRemoveKeyEntry class >> journalTypeCode [
	^ 4
]

{ #category : #accessing }
SoilRemoveKeyEntry >> address [
	^ key asByteArray asString
]

{ #category : #committing }
SoilRemoveKeyEntry >> commitIn: soil recovery: aBoolean [
	| iterator index |
	index := ((soil objectRepository segmentAt: self segment) indexAt: id).
	iterator := index newIterator.
	"on recovery we ignore a missing key because it can be removed already and the replay
	would fail always. But we still want to fail in a regular commit"
	aBoolean 
		ifTrue: [ 
			index hasUniqueKeys 
				ifTrue: [ iterator removeKey: key ifAbsent: [ "ignore missing key" ] ]
				ifFalse: [ iterator removeKey: key value: oldValue ifAbsent: [ "ignore missing key" ] ] ]
		ifFalse: [ 
			index hasUniqueKeys 
				ifTrue: [ iterator removeKey: key ]
				ifFalse: [ iterator removeKey: key value: oldValue ]
			 ].
	iterator updateCurrentTransaction: transactionId 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> context [ 
	^ id 
]

{ #category : #testing }
SoilRemoveKeyEntry >> isForItem: anItem index: indexId [
	id = indexId ifFalse: [ ^false ].
	
	^ key = anItem key and: [
		anItem value isRemoved and: [
			anItem value isRestorable and: [
				SoilIndexItemsPage value: anItem value removedId matches: oldValue ] ] ]

]

{ #category : #accessing }
SoilRemoveKeyEntry >> key [

	^ key
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> objectIds [
	^ { oldValue }
]

{ #category : #accessing }
SoilRemoveKeyEntry >> oldValue [

	^ oldValue
]

{ #category : #accessing }
SoilRemoveKeyEntry >> oldValue: aString [ 
	oldValue := aString
]

{ #category : #testing }
SoilRemoveKeyEntry >> providesObjectIds [ 
	^ true
]

{ #category : #'instance creation' }
SoilRemoveKeyEntry >> readFrom: aStream [
	| idSize |
	super readFrom: aStream.
	idSize := aStream next.
	id := (aStream next: idSize) asString.
	key := (aStream next: aStream nextLengthEncodedInteger) asInteger.
	oldValue := (aStream next: aStream nextLengthEncodedInteger) asSoilObjectId .
]

{ #category : #validating }
SoilRemoveKeyEntry >> isAddedEarlierInTheJournal [
	"whether this transaction added the key itself before removing it. It is not in the
	persistent index then, and it does not have to be"
	journal entries do: [ :each |
		each == self ifTrue: [ ^ false ].
		((each isKindOf: SoilAddKeyEntry) and: [ each id = id and: [ each key = key ] ])
			ifTrue: [ ^ true ] ].
	^ false
]

{ #category : #validating }
SoilRemoveKeyEntry >> isPresentIn: anIndex [
	"whether the persistent index still holds the entry this removal is about. A removed
	entry stays in the page with a removed id as its value until the index cleaner drops it,
	so both a missing key and a removed value mean it is gone"
	| iterator |
	iterator := anIndex newIterator.
	^ anIndex hasUniqueKeys
		ifTrue: [
			(iterator at: key ifAbsent: [ nil ])
				ifNil: [ false ]
				ifNotNil: [ :value | value isRemoved not ] ]
		ifFalse: [
			(iterator at: key ifAbsent: [ #() ]) anySatisfy: [ :value |
				value isRemoved not and: [
					SoilIndexItemsPage value: value matches: oldValue ] ] ]
]

{ #category : #validating }
SoilRemoveKeyEntry >> validateIn: aSoilTransaction [
	"the transaction found the key in the index when it read it. If another transaction has
	removed it or moved it away since, applying this entry would fail with KeyNotFound
	after the journal is written (unique keys), or bury the entry a second time without a
	word. Both are a concurrent change, and here, before the journal is written, it can
	still be said as one"
	| index |
	self isAddedEarlierInTheJournal ifTrue: [ ^ self ].
	index := (aSoilTransaction soil objectRepository segmentAt: self segment) indexAt: id.
	(self isPresentIn: index) ifTrue: [ ^ self ].
	SoilIndexHasConcurrentChange new
		objectId: oldValue;
		indexId: id;
		key: key;
		signal
]

{ #category : #writing }
SoilRemoveKeyEntry >> writeOn: aStream [ 
	| keyByteArray oldValueByteArray |
	keyByteArray := key asByteArray.
	oldValueByteArray := oldValue asByteArray.
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: keyByteArray size;
		nextPutAll: keyByteArray;
		nextPutLengthEncodedInteger: oldValueByteArray size;
		nextPutAll: oldValueByteArray
		
]
