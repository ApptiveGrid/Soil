"
A SoilIndexQuery describes what to read from a SoilDerivedIndex: an optional range of keys, a
key to start after, how many hits to skip, how many to deliver at most, and a predicate that
the hits have to satisfy. It holds no reading state, so it can be kept, passed on, changed and
used again; #iterator makes a new SoilIndexQueryIterator that runs it.

	query := index queryFor: 'Doe'.
	query limit: 20; predicate: [ :each | each age > 18 ].
	page := query iterator upToEnd.
	nextPage := (query copy after: iterator position) iterator next: 20.

The start is exclusive: the key it names is not delivered. It is the way to read on, offset is
offered as well but costs as many steps as it skips, and with a predicate each skipped hit is
loaded. The limit counts hits, not entries read. #count reads to the end and counts what range
and predicate let through, whatever start, offset and limit say. Reading is forwards only.

The index is read through its transaction, the iterator sees what the transaction changed and a
reader with an older version sees the older state.
"
Class {
	#name : #SoilIndexQuery,
	#superclass : #Object,
	#instVars : [
		'index',
		'range',
		'after',
		'offset',
		'limit',
		'predicate'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilIndexQuery class >> on: aSoilDerivedIndex [
	^ self new
		index: aSoilDerivedIndex;
		yourself
]

{ #category : #accessing }
SoilIndexQuery >> after [
	"the key to start after, not included, as an index key or nil"
	^ after
]

{ #category : #accessing }
SoilIndexQuery >> after: aKey [
	"start after aKey, a whole key as #position of an iterator hands it out. Not included, and
	not an error if no entry has it any more: reading begins with the next one there is"
	after := aKey ifNotNil: [ index indexKey: aKey ]
]

{ #category : #reading }
SoilIndexQuery >> count [
	"how many entries range and predicate let through, counted by reading them all. Start, offset
	and limit do not apply"
	| iterator count |
	iterator := (SoilIndexQuery on: index)
		range: range;
		predicate: predicate;
		iterator.
	count := 0.
	[ iterator next notNil ] whileTrue: [ count := count + 1 ].
	^ count
]

{ #category : #accessing }
SoilIndexQuery >> index [
	^ index
]

{ #category : #accessing }
SoilIndexQuery >> index: aSoilDerivedIndex [
	index := aSoilDerivedIndex
]

{ #category : #reading }
SoilIndexQuery >> iterator [
	"a new iterator, it starts at the beginning of the query and does not know any other"
	^ SoilIndexQueryIterator on: self
]

{ #category : #accessing }
SoilIndexQuery >> limit [
	^ limit
]

{ #category : #accessing }
SoilIndexQuery >> limit: anInteger [
	"the most hits an iterator delivers, nil for all"
	limit := anInteger
]

{ #category : #accessing }
SoilIndexQuery >> offset [
	^ offset
]

{ #category : #accessing }
SoilIndexQuery >> offset: anInteger [
	"how many hits are skipped after the start before the first is delivered"
	offset := anInteger
]

{ #category : #accessing }
SoilIndexQuery >> predicate [
	^ predicate
]

{ #category : #accessing }
SoilIndexQuery >> predicate: aValuable [
	"anything that understands #value:, a block or a symbol, it is given the indexed object. Hits
	are the entries it answers true for"
	predicate := aValuable
]

{ #category : #printing }
SoilIndexQuery >> printOn: aStream [
	super printOn: aStream.
	aStream << ' on ' << index printString
]

{ #category : #accessing }
SoilIndexQuery >> range [
	"a SoilIndexRange, nil for the whole index"
	^ range
]

{ #category : #accessing }
SoilIndexQuery >> range: aSoilIndexRange [
	range := aSoilIndexRange
]
