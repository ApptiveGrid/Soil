"
A SoilQueryIterator is what a SoilQuery answers to #iterator. It reads through the iterator of
whatever the planner chose and adds the position as values, which is the same for an index and a scan.
It answers the reading protocol of an index iterator: #next, #next:, #do:, #atEnd, #upToEnd and #first,
and #position, the SoilQueryPosition of the hit delivered last, nil before the first.
"
Class {
	#name : #SoilQueryIterator,
	#superclass : #Object,
	#instVars : [
		'query',
		'iterator',
		'last'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilQueryIterator class >> on: aSoilQuery plan: anIterator [
	^ self new
		setQuery: aSoilQuery iterator: anIterator;
		yourself
]

{ #category : #testing }
SoilQueryIterator >> atEnd [
	^ iterator atEnd
]

{ #category : #enumerating }
SoilQueryIterator >> do: aBlock [
	iterator do: [ :each |
		last := each.
		aBlock value: each ]
]

{ #category : #accessing }
SoilQueryIterator >> first [
	^ last := iterator first
]

{ #category : #accessing }
SoilQueryIterator >> next [
	| next |
	next := iterator next.
	next ifNotNil: [ last := next ].
	^ next
]

{ #category : #accessing }
SoilQueryIterator >> next: anInteger [
	| result next |
	result := OrderedCollection new: anInteger.
	[ result size < anInteger and: [ (next := self next) notNil ] ] whileTrue: [ result add: next ].
	^ result
]

{ #category : #accessing }
SoilQueryIterator >> position [
	"the place of the hit delivered last, as values: its property and its primary value"
	| primarySelector |
	last ifNil: [ ^ nil ].
	primarySelector := query collection primaryIndex selector.
	^ query property
		ifNil: [ SoilQueryPosition primary: (last perform: primarySelector) ]
		ifNotNil: [ :selector |
			SoilQueryPosition
				attribute: (last perform: selector)
				primary: (last perform: primarySelector) ]
]

{ #category : #accessing }
SoilQueryIterator >> query [
	^ query
]

{ #category : #initialization }
SoilQueryIterator >> setQuery: aSoilQuery iterator: anIterator [
	query := aSoilQuery.
	iterator := anIterator
]

{ #category : #enumerating }
SoilQueryIterator >> upToEnd [
	| result next |
	result := OrderedCollection new.
	[ (next := self next) notNil ] whileTrue: [ result add: next ].
	^ result
]
