"
A SoilScanQuery is what a SoilQueryPlanner answers when the collection has no index on the property of the
query: it reads the primary and checks comparison and predicate at every object. It answers #iterator and
#count like a SoilIndexQuery and gives the same elements in the same order, by the property through its
SoilKeyEncoding and then by the primary key.

The primary is in the order of the primary key. A query for one value, equal to it, needs no sorting and reads
the primary through an index query whose predicate is the check, so it stops when the limit is reached. A
query for a range, for a start of the value or for the whole property reads every hit, sorts them in memory
and only then applies the position, the offset and the limit.

Equality and order are those of the encoding of the query, the standard one unless it brings another. A
value that the encoding refuses, nil for one, is an error, as it is when it is put into an index.
"
Class {
	#name : #SoilScanQuery,
	#superclass : #Object,
	#instVars : [
		'query',
		'collection'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilScanQuery class >> on: aSoilQuery in: aSoilIndexedCollection [
	^ self new
		setQuery: aSoilQuery collection: aSoilIndexedCollection;
		yourself
]

{ #category : #reading }
SoilScanQuery >> count [
	"how many objects comparison and predicate let through, whatever position, offset and limit say"
	^ (self primaryQuery
		predicate: self hitBlock;
		yourself) count
]

{ #category : #private }
SoilScanQuery >> encoding [
	^ query encoding ifNil: [ SoilKeyEncoding standard ]
]

{ #category : #private }
SoilScanQuery >> hitBlock [
	"true for an object that satisfies comparison and predicate of the query"
	| encoding comparison property predicate |
	encoding := self encoding.
	comparison := query comparison.
	property := query property.
	predicate := query predicate.
	^ [ :each |
		(comparison isNil or: [
			[ comparison matches: (each perform: property) encoding: encoding ]
				on: SoilUnsupportedError
				do: [ :error |
					SoilUnsupportedError signal: 'property #' , property asString , ' of ' , each printString , ': ' , error messageText ] ])
			and: [ predicate isNil or: [ (predicate value: each) == true ] ] ]
]

{ #category : #private }
SoilScanQuery >> isHit: anObject after: aPosition [
	"whether anObject comes after the position: by the property, then by the primary key"
	| order |
	query property ifNotNil: [ :property |
		aPosition attribute isNil ifTrue: [
			^ SoilUnsupportedError signal: 'a position without a value of the property cannot start a query on #' , property asString ].
		order := self encoding compare: (anObject perform: property) with: aPosition attribute.
		order = 0 ifFalse: [ ^ order > 0 ] ].
	^ (collection primaryIndex layout encoding
		compare: (anObject perform: collection primaryIndex selector)
		with: aPosition primary) > 0
]

{ #category : #private }
SoilScanQuery >> isOrderedByPrimaryKey [
	"whether the primary key order is the order asked for: all hits have the one value of an equal comparison"
	^ query comparison notNil and: [ query comparison isEqual ]
]

{ #category : #reading }
SoilScanQuery >> iterator [
	^ self isOrderedByPrimaryKey
		ifTrue: [ self unsortedIterator ]
		ifFalse: [ self sortedIterator ]
]

{ #category : #private }
SoilScanQuery >> orderOf: anObject before: another [
	"whether anObject comes before another: by the property through the encoding, then by the primary key"
	| property primarySelector order |
	property := query property.
	primarySelector := collection primaryIndex selector.
	order := self encoding compare: (anObject perform: property) with: (another perform: property).
	order = 0 ifFalse: [ ^ order < 0 ].
	^ (collection primaryIndex layout encoding
		compare: (anObject perform: primarySelector)
		with: (another perform: primarySelector)) < 0
]

{ #category : #private }
SoilScanQuery >> primaryQuery [
	"an index query over the whole primary"
	^ collection primaryIndex query
]

{ #category : #private }
SoilScanQuery >> setQuery: aSoilQuery collection: aSoilIndexedCollection [
	query := aSoilQuery.
	collection := aSoilIndexedCollection
]

{ #category : #private }
SoilScanQuery >> sortedIterator [
	"reads every hit, sorts, then drops what is before the position and applies offset and limit"
	| hits sorted |
	hits := (self primaryQuery
		predicate: self hitBlock;
		yourself) iterator upToEnd.
	sorted := hits asArray sort: [ :one :other | self orderOf: one before: other ].
	query after ifNotNil: [ :position |
		sorted := sorted select: [ :each | self isHit: each after: position ] ].
	sorted := query offset
		ifNil: [ sorted ]
		ifNotNil: [ :offset | sorted allButFirst: (offset min: sorted size) ].
	query limit ifNotNil: [ :limit | sorted := sorted first: (limit min: sorted size) ].
	^ SoilScanIterator on: sorted
]

{ #category : #private }
SoilScanQuery >> unsortedIterator [
	"the primary in its own order, which is the one asked for"
	| indexQuery |
	indexQuery := self primaryQuery
		predicate: self hitBlock;
		offset: query offset;
		limit: query limit;
		yourself.
	query after ifNotNil: [ :position |
		indexQuery after: (collection primaryIndex layout keyFor: position primary primaryKey: nil) ].
	^ indexQuery iterator
]
