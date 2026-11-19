"
A SoilIndexQueryIterator runs a SoilIndexQuery. It stands at a place in the range of the query and
counts the hits it has delivered. It holds a SoilIndexIterator of the index and only reads.

It answers the reading protocol of a SoilIndexIterator without being one: #next, #next:, #do:,
#atEnd, #upToEnd and #first. #next answers the next hit, the indexed object, or nil at the end,
which is the end of the range or the limit. #atEnd looks one hit ahead, with a predicate it reads on
until it finds one or the range ends; the hit is kept for #next. #first starts the query over and
answers its first hit, like #first of an index iterator does for the index, and #do: starts over as
well, #upToEnd goes on from where the iterator stands. There is no #size, the size of an index is
that of the whole index, #count of the query counts hits.

#position is the whole key of the last hit delivered, a ByteArray, nil before the first. A query
that starts after it reads on without a gap and without doubles, in any transaction.
"
Class {
	#name : #SoilIndexQueryIterator,
	#superclass : #Object,
	#instVars : [
		'query',
		'iterator',
		'started',
		'skipped',
		'delivered',
		'ahead',
		'lastKey'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilIndexQueryIterator class >> on: aSoilIndexQuery [
	^ self new
		query: aSoilIndexQuery;
		yourself
]

{ #category : #testing }
SoilIndexQueryIterator >> atEnd [
	^ self lookAhead isNil
]

{ #category : #enumerating }
SoilIndexQueryIterator >> do: aBlock [
	| next |
	self restart.
	[ (next := self next) notNil ] whileTrue: [ aBlock value: next ]
]

{ #category : #accessing }
SoilIndexQueryIterator >> first [
	self restart.
	^ self next
]

{ #category : #private }
SoilIndexQueryIterator >> hitAfter: aKey [
	"the first hit at or after aKey as key -> object, or nil. Positions the iterator of the index"
	| found entry |
	found := iterator nextKeyCloseTo: aKey.
	found ifNil: [ ^ nil ].
	(self isInRange: found) ifFalse: [ ^ nil ].
	entry := found -> (iterator at: found).
	(self isHit: entry value) ifTrue: [ ^ entry ].
	^ self hitFollowing
]

{ #category : #private }
SoilIndexQueryIterator >> hitFollowing [
	"the next hit after the entry read last as key -> object, or nil"
	| found |
	[ (found := iterator nextAssociation) notNil ] whileTrue: [
		(self isInRange: found key) ifFalse: [ ^ nil ].
		(self isHit: found value) ifTrue: [ ^ found key -> found value ] ].
	^ nil
]

{ #category : #private }
SoilIndexQueryIterator >> isHit: anObject [
	^ query predicate isNil or: [ (query predicate value: anObject) == true ]
]

{ #category : #private }
SoilIndexQueryIterator >> isInRange: anIndexKey [
	^ query range isNil or: [ query range includesKey: anIndexKey ]
]

{ #category : #private }
SoilIndexQueryIterator >> lookAhead [
	"the next hit to deliver as key -> object, read when it is first asked for and kept until #next
	takes it. nil at the end of the range and at the limit"
	ahead ifNotNil: [ ^ ahead ].
	(query limit notNil and: [ delivered >= query limit ]) ifTrue: [ ^ nil ].
	ahead := self readHit.
	^ ahead
]

{ #category : #accessing }
SoilIndexQueryIterator >> next [
	| hit |
	hit := self lookAhead ifNil: [ ^ nil ].
	ahead := nil.
	delivered := delivered + 1.
	lastKey := hit key.
	^ hit value
]

{ #category : #accessing }
SoilIndexQueryIterator >> next: anInteger [
	| result next |
	result := OrderedCollection new: anInteger.
	[ result size < anInteger and: [ (next := self next) notNil ] ] whileTrue: [ result add: next ].
	^ result
]

{ #category : #accessing }
SoilIndexQueryIterator >> position [
	"the whole key of the last hit delivered, nil if there was none"
	^ lastKey ifNotNil: [ :key | key asByteArrayOfSize: query index layout keySize ]
]

{ #category : #accessing }
SoilIndexQueryIterator >> query [
	^ query
]

{ #category : #initialization }
SoilIndexQueryIterator >> query: aSoilIndexQuery [
	query := aSoilIndexQuery.
	self restart
]

{ #category : #private }
SoilIndexQueryIterator >> readHit [
	"reads on from where the last read stopped. The first read positions at the start of the query,
	and skips the offset"
	| hit |
	started
		ifTrue: [ hit := self hitFollowing ]
		ifFalse: [
			started := true.
			hit := self hitAfter: self startKey ].
	[ hit notNil and: [ skipped < (query offset ifNil: [ 0 ]) ] ] whileTrue: [
		skipped := skipped + 1.
		hit := self hitFollowing ].
	^ hit
]

{ #category : #initialization }
SoilIndexQueryIterator >> restart [
	iterator := query index newIterator.
	started := false.
	skipped := 0.
	delivered := 0.
	ahead := nil.
	lastKey := nil
]

{ #category : #private }
SoilIndexQueryIterator >> startKey [
	"the key to look for the first entry from: the one after the key to start after, else the first
	key of the range, else the first of the index"
	^ query after
		ifNotNil: [ :key | key + 1 ]
		ifNil: [ query range ifNil: [ 0 ] ifNotNil: [ :range | range firstIndexKey ] ]
]

{ #category : #enumerating }
SoilIndexQueryIterator >> upToEnd [
	"all hits from where the iterator stands, answers a collection"
	| result next |
	result := OrderedCollection new.
	[ (next := self next) notNil ] whileTrue: [ result add: next ].
	^ result
]
