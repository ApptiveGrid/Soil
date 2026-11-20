"
A SoilQueryPlanner turns the SoilQuery of a user into what reads, for one SoilIndexedCollection. It has one rule:
if the collection has an index on the property of the query, the primary counts, the planner builds a
SoilIndexQuery from it with the range of the comparison, the predicate, the position, offset and limit.
If it has none, it answers a SoilFullScanQuery that reads the primary and checks comparison and predicate at
every object. A query without a property reads the primary.

Both answer #iterator and #count, and both give the same elements in the same order: by the property
through its encoding, then by the primary key. An index is only a speed-up.

An index with a predicate, a partial index, is never chosen here, it does not hold every element. There
are none yet; when there are, they are named explicitly and read through an index query built by hand.
"
Class {
	#name : #SoilQueryPlanner,
	#superclass : #Object,
	#instVars : [
		'collection'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilQueryPlanner class >> on: aSoilIndexedCollection [
	^ self new
		collection: aSoilIndexedCollection;
		yourself
]

{ #category : #accessing }
SoilQueryPlanner >> collection: aSoilIndexedCollection [
	collection := aSoilIndexedCollection
]

{ #category : #private }
SoilQueryPlanner >> indexQueryFor: aSoilQuery on: anIndex [
	| indexQuery |
	indexQuery := anIndex query.
	aSoilQuery comparison ifNotNil: [ :comparison |
		indexQuery range: (comparison rangeIn: anIndex layout) ].
	indexQuery
		predicate: aSoilQuery predicate;
		offset: aSoilQuery offset;
		limit: aSoilQuery limit.
	aSoilQuery isBackward ifTrue: [ indexQuery backwards ].
	aSoilQuery start ifNotNil: [ :position | | key |
		key := self keyOf: position in: anIndex for: aSoilQuery.
		aSoilQuery isBackward
			ifTrue: [ indexQuery before: key ]
			ifFalse: [ indexQuery after: key ] ].
	^ indexQuery
]

{ #category : #private }
SoilQueryPlanner >> keyOf: aPosition in: anIndex for: aSoilQuery [
	"the whole key of the entry a position stands for in anIndex"
	| primaryLayout |
	primaryLayout := collection primaryIndex layout.
	anIndex id = collection primaryIndex id ifTrue: [
		^ primaryLayout keyFor: aPosition primary primaryKey: nil ].
	aPosition attribute isNil ifTrue: [
		^ SoilUnsupportedError signal: 'a position without a value of the property cannot start a query on #' , aSoilQuery property asString ].
	^ anIndex layout
		keyFor: aPosition attribute
		primaryKey: (primaryLayout keyFor: aPosition primary primaryKey: nil)
]

{ #category : #planning }
SoilQueryPlanner >> plan: aSoilQuery [
	"an index query or a scan, as the rule in the class comment says"
	| index |
	(aSoilQuery property isNil and: [ aSoilQuery comparison notNil ]) ifTrue: [
		^ SoilUnsupportedError signal: 'a comparison needs the property it is about' ].
	index := aSoilQuery property
		ifNil: [ collection primaryIndex ]
		ifNotNil: [ :property | collection indexFor: property ].
	^ index
		ifNil: [ SoilFullScanQuery on: aSoilQuery in: collection ]
		ifNotNil: [ self indexQueryFor: aSoilQuery on: index ]
]
