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

The query decides the direction. A backward query reads from the end of its range, or from before the
key it starts before, to the beginning, and #next, #position, the offset and the limit follow that
direction. The last element of a range is #first of a backward query.
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

{ #category : #private }
SoilIndexQueryIterator >> backwardBound [
	"where a backward read starts as key -> whether that key is left out, or nil for the end of the index.
	Of the end of the range and the key to start before the one that comes first in the direction of
	reading counts. Keys are compared, nothing is added to them"
	| range before bound |
	range := query range.
	before := query start.
	bound := range ifNotNil: [ range lastIndexKey -> range includesLast not ].
	before ifNil: [ ^ bound ].
	^ (bound isNil or: [ before <= bound key ])
		ifTrue: [ before -> true ]
		ifFalse: [ bound ]
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
SoilIndexQueryIterator >> forwardBound [
	"where a forward read starts as key -> whether that key is left out, or nil for the start of the index"
	| range after bound |
	range := query range.
	after := query start.
	bound := range ifNotNil: [ range firstIndexKey -> range includesFirst not ].
	after ifNil: [ ^ bound ].
	^ (bound isNil or: [ after >= bound key ])
		ifTrue: [ after -> true ]
		ifFalse: [ bound ]
]

{ #category : #private }
SoilIndexQueryIterator >> hitAt: aFoundKey leaving: aBoolean key: aKey [
	"the first hit from the entry the iterator of the index was positioned on, found as aFoundKey, in
	the direction of reading, as key -> object, or nil. When the entry of aKey itself is to be left
	out it is stepped over"
	| entry |
	aFoundKey ifNil: [ ^ nil ].
	(aBoolean and: [ aFoundKey = aKey ]) ifTrue: [ ^ self hitFollowing ].
	(self isInRange: aFoundKey) ifFalse: [ ^ nil ].
	entry := aFoundKey -> (iterator at: aFoundKey).
	(self isHit: entry value) ifTrue: [ ^ entry ].
	^ self hitFollowing
]

{ #category : #private }
SoilIndexQueryIterator >> hitFollowing [
	"the next hit after the entry read last, in the direction of reading, as key -> object, or nil"
	| found |
	[ (found := self nextAssociationInDirection) notNil ] whileTrue: [
		(self isInRange: found key) ifFalse: [ ^ nil ].
		(self isHit: found value) ifTrue: [ ^ found key -> found value ] ].
	^ nil
]

{ #category : #private }
SoilIndexQueryIterator >> hitFromStart [
	"the first hit of the query in the direction of reading, as key -> object, or nil. A bound that is
	left out is started like a start after a key"
	| bound |
	query isBackward ifTrue: [
		bound := self backwardBound.
		bound ifNil: [ ^ self hitOfLastEntry ].
		^ self
			hitAt: (iterator previousKeyCloseTo: bound key)
			leaving: bound value
			key: bound key ].
	bound := self forwardBound.
	bound ifNil: [ ^ self hitAt: (iterator nextKeyCloseTo: 0) leaving: false key: 0 ].
	^ self
		hitAt: (iterator nextKeyCloseTo: bound key)
		leaving: bound value
		key: bound key
]

{ #category : #private }
SoilIndexQueryIterator >> hitOfLastEntry [
	"the last hit of the index, for a backward read that has neither a range nor a start"
	| last |
	last := iterator lastAssociation ifNil: [ ^ nil ].
	(self isHit: last value) ifTrue: [ ^ last key -> last value ].
	^ self hitFollowing
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

{ #category : #private }
SoilIndexQueryIterator >> nextAssociationInDirection [
	^ query isBackward
		ifTrue: [ iterator previousAssociation ]
		ifFalse: [ iterator nextAssociation ]
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
			hit := self hitFromStart ].
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

{ #category : #enumerating }
SoilIndexQueryIterator >> upToEnd [
	"all hits from where the iterator stands, answers a collection"
	| result next |
	result := OrderedCollection new.
	[ (next := self next) notNil ] whileTrue: [ result add: next ].
	^ result
]
