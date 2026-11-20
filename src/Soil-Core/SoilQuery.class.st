"
A SoilQuery is what a user asks of a SoilIndexedCollection: elements whose property satisfies a
comparison and a predicate, from a position on, with an offset and a limit. It speaks in values and
names no index. A SoilQueryPlanner turns it into what reads, an index query when the collection has an
index on the property and a scan of the primary when it has none; the elements and their order are the
same. An index is only a speed-up.

	query := collection query.
	query property: #lastName; equalTo: 'Doe'; predicate: [ :each | each age > 18 ]; limit: 20.
	iterator := query iterator.
	page := iterator upToEnd.
	next := (query copy after: iterator position; yourself) iterator next: 20.

The property is a symbol, the selector of an index, and may be left out: all elements, in the order of
their primary key. The comparison is data, the predicate is anything that understands #value: and checks
the rest at the object. The order of the result is that of the property by its SoilKeyEncoding, then that
of the primary key. The position is exclusive, offset and limit count hits.

A query can be kept and used again. It brings its own encoding with #encoding: for a read without an index.

It reads forwards unless it is told #backwards. A backward query reads the same elements in the reverse order,
and offset, limit and the position count in the direction of reading. #after: starts forwards after a position,
#before: starts backwards before it, each also sets the direction. The page before a position:

	page := (query copy before: position; limit: 20; yourself) iterator upToEnd reverse.
"
Class {
	#name : #SoilQuery,
	#superclass : #Object,
	#instVars : [
		'collection',
		'property',
		'comparison',
		'predicate',
		'start',
		'backward',
		'offset',
		'limit',
		'encoding'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilQuery class >> on: aSoilIndexedCollection [
	^ self new
		collection: aSoilIndexedCollection;
		yourself
]

{ #category : #accessing }
SoilQuery >> after [
	"the position a forward query starts after, nil for a backward query and when there is none"
	^ backward ifTrue: [ nil ] ifFalse: [ start ]
]

{ #category : #accessing }
SoilQuery >> after: aSoilQueryPosition [
	"read forwards, starting after this position, not at it. Not an error if no element is there any
	more. nil for no start"
	backward := false.
	start := aSoilQueryPosition
]

{ #category : #accessing }
SoilQuery >> backwards [
	"read in the reverse order"
	backward := true
]

{ #category : #accessing }
SoilQuery >> before [
	"the position a backward query starts before, nil for a forward query and when there is none"
	^ backward ifTrue: [ start ] ifFalse: [ nil ]
]

{ #category : #accessing }
SoilQuery >> before: aSoilQueryPosition [
	"read backwards, starting before this position, not at it. Not an error if no element is there any
	more. nil for no start"
	backward := true.
	start := aSoilQueryPosition
]

{ #category : #accessing }
SoilQuery >> collection [
	^ collection
]

{ #category : #accessing }
SoilQuery >> collection: aSoilIndexedCollection [
	collection := aSoilIndexedCollection
]

{ #category : #accessing }
SoilQuery >> comparison [
	^ comparison
]

{ #category : #accessing }
SoilQuery >> comparison: aSoilQueryComparison [
	comparison := aSoilQueryComparison
]

{ #category : #copying }
SoilQuery >> copyWithoutPaging [
	^ self copy
		after: nil;
		offset: nil;
		limit: nil;
		yourself
]

{ #category : #reading }
SoilQuery >> count [
	"how many elements comparison and predicate let through, counted by reading them. Position,
	offset and limit do not apply"
	^ (self planner plan: self copyWithoutPaging) count
]

{ #category : #accessing }
SoilQuery >> encoding [
	"the encoding that gives equality and order of the property for a read without an index, nil for
	the standard one"
	^ encoding
]

{ #category : #accessing }
SoilQuery >> encoding: aSoilKeyEncoding [
	encoding := aSoilKeyEncoding
]

{ #category : #comparing }
SoilQuery >> equalTo: aValue [
	comparison := SoilQueryComparison equalTo: aValue
]

{ #category : #accessing }
SoilQuery >> forwards [
	"read in the order of the property and the primary key, the default"
	backward := false
]

{ #category : #comparing }
SoilQuery >> from: aLowValue to: aHighValue [
	comparison := SoilQueryComparison from: aLowValue to: aHighValue
]

{ #category : #comparing }
SoilQuery >> from: aLowValue to: aHighValue includeFirst: firstBoolean includeLast: lastBoolean [
	comparison := SoilQueryComparison
		from: aLowValue
		to: aHighValue
		includeFirst: firstBoolean
		includeLast: lastBoolean
]

{ #category : #initialization }
SoilQuery >> initialize [
	super initialize.
	backward := false
]

{ #category : #testing }
SoilQuery >> isBackward [
	^ backward
]

{ #category : #reading }
SoilQuery >> iterator [
	"a new iterator, at the start of the query and unaware of any other"
	^ SoilQueryIterator on: self plan: (self planner plan: self) iterator
]

{ #category : #accessing }
SoilQuery >> limit [
	^ limit
]

{ #category : #accessing }
SoilQuery >> limit: anInteger [
	"the most hits that are delivered, nil for all"
	limit := anInteger
]

{ #category : #accessing }
SoilQuery >> offset [
	^ offset
]

{ #category : #accessing }
SoilQuery >> offset: anInteger [
	"how many hits are skipped after the position before the first is delivered"
	offset := anInteger
]

{ #category : #reading }
SoilQuery >> plan [
	"what reads for this query, chosen by the planner: an index query or a scan, which both
	answer #iterator and #count"
	^ self planner plan: self
]

{ #category : #private }
SoilQuery >> planner [
	^ SoilQueryPlanner on: collection
]

{ #category : #accessing }
SoilQuery >> predicate [
	^ predicate
]

{ #category : #accessing }
SoilQuery >> predicate: aValuable [
	"anything that understands #value:, a block or a symbol, it checks the element and is not the
	comparison. The planner does not look into it"
	predicate := aValuable
]

{ #category : #printing }
SoilQuery >> printOn: aStream [
	super printOn: aStream.
	aStream << ' on #' << property asString
]

{ #category : #accessing }
SoilQuery >> property [
	^ property
]

{ #category : #accessing }
SoilQuery >> property: aSymbol [
	"the property that comparison and order are about, the selector of an index on it if there is one.
	nil for none"
	property := aSymbol ifNotNil: [ :each | each asSymbol ]
]

{ #category : #accessing }
SoilQuery >> start [
	"the position reading starts after, in the direction of reading, or nil"
	^ start
]

{ #category : #comparing }
SoilQuery >> startingWith: someBytes [
	comparison := SoilQueryComparison startingWith: someBytes
]
