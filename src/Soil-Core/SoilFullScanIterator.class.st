"
A SoilFullScanIterator reads a list of objects that a SoilFullScanQuery has collected and sorted. It answers the
reading protocol of an index iterator: #next, #next:, #do:, #atEnd, #upToEnd and #first. #do: and #first start
over, #upToEnd goes on from where the iterator stands.
"
Class {
	#name : #SoilFullScanIterator,
	#superclass : #Object,
	#instVars : [
		'objects',
		'index'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilFullScanIterator class >> on: aCollection [
	^ self new
		setObjects: aCollection;
		yourself
]

{ #category : #testing }
SoilFullScanIterator >> atEnd [
	^ index >= objects size
]

{ #category : #enumerating }
SoilFullScanIterator >> do: aBlock [
	index := 0.
	[ self atEnd ] whileFalse: [ aBlock value: self next ]
]

{ #category : #accessing }
SoilFullScanIterator >> first [
	index := 0.
	^ self next
]

{ #category : #accessing }
SoilFullScanIterator >> next [
	self atEnd ifTrue: [ ^ nil ].
	index := index + 1.
	^ objects at: index
]

{ #category : #accessing }
SoilFullScanIterator >> next: anInteger [
	| result next |
	result := OrderedCollection new: anInteger.
	[ result size < anInteger and: [ (next := self next) notNil ] ] whileTrue: [ result add: next ].
	^ result
]

{ #category : #initialization }
SoilFullScanIterator >> setObjects: aCollection [
	objects := aCollection.
	index := 0
]

{ #category : #enumerating }
SoilFullScanIterator >> upToEnd [
	| result |
	result := OrderedCollection new.
	[ self atEnd ] whileFalse: [ result add: self next ].
	^ result
]
