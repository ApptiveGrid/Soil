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
and predicate let through, whatever start, offset, limit and direction say.

Reading goes forwards unless the query is told #backwards. Then it reads from the end of the range to
its beginning, and offset, limit and predicate count in the direction of reading. #after: starts
forwards after a key, #before: starts backwards before a key; each also sets the direction. The page
before a position is read backwards from it and turned around:

	page := (query copy before: position; yourself) iterator upToEnd reverse.

The index is read through its transaction, the iterator sees what the transaction changed and a
reader with an older version sees the older state.
"
Class {
	#name : #SoilIndexQuery,
	#superclass : #Object,
	#instVars : [
		'index',
		'range',
		'start',
		'backward',
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
	"the key a forward query starts after, not included, as an index key; nil for a backward query
	and when there is no start"
	^ backward ifTrue: [ nil ] ifFalse: [ start ]
]

{ #category : #accessing }
SoilIndexQuery >> after: aKey [
	"read forwards, starting after aKey, a whole key as #position of an iterator hands it out. Not
	included, and not an error if no entry has it any more: reading begins with the next one there
	is. nil for no start"
	backward := false.
	start := aKey ifNotNil: [ index indexKey: aKey ]
]

{ #category : #accessing }
SoilIndexQuery >> backwards [
	"read from the end of the range to its beginning"
	backward := true
]

{ #category : #accessing }
SoilIndexQuery >> before [
	"the key a backward query starts before, not included, as an index key; nil for a forward query
	and when there is no start"
	^ backward ifTrue: [ start ] ifFalse: [ nil ]
]

{ #category : #accessing }
SoilIndexQuery >> before: aKey [
	"read backwards, starting before aKey, not included, and not an error if no entry has it any
	more: reading begins with the previous one there is. nil for no start"
	backward := true.
	start := aKey ifNotNil: [ index indexKey: aKey ]
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
SoilIndexQuery >> forwards [
	"read from the beginning of the range to its end, the default"
	backward := false
]

{ #category : #accessing }
SoilIndexQuery >> index [
	^ index
]

{ #category : #accessing }
SoilIndexQuery >> index: aSoilDerivedIndex [
	index := aSoilDerivedIndex
]

{ #category : #initialization }
SoilIndexQuery >> initialize [
	super initialize.
	backward := false
]

{ #category : #testing }
SoilIndexQuery >> isBackward [
	^ backward
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

{ #category : #accessing }
SoilIndexQuery >> start [
	"the key reading starts after, in the direction of reading, as an index key, or nil"
	^ start
]
