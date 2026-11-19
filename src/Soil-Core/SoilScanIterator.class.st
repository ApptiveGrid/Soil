"
A SoilScanIterator reads a list of objects that a SoilScanQuery has collected and sorted. It answers the
reading protocol of an index iterator: #next, #next:, #do:, #atEnd, #upToEnd and #first. #do: and #first start
over, #upToEnd goes on from where the iterator stands.
"
Class {
	#name : #SoilScanIterator,
	#superclass : #Object,
	#instVars : [
		'objects',
		'index'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilScanIterator class >> on: aCollection [
	^ self new
		setObjects: aCollection;
		yourself
]

{ #category : #testing }
SoilScanIterator >> atEnd [
	^ index >= objects size
]

{ #category : #enumerating }
SoilScanIterator >> do: aBlock [
	index := 0.
	[ self atEnd ] whileFalse: [ aBlock value: self next ]
]

{ #category : #accessing }
SoilScanIterator >> first [
	index := 0.
	^ self next
]

{ #category : #accessing }
SoilScanIterator >> next [
	self atEnd ifTrue: [ ^ nil ].
	index := index + 1.
	^ objects at: index
]

{ #category : #accessing }
SoilScanIterator >> next: anInteger [
	| result next |
	result := OrderedCollection new: anInteger.
	[ result size < anInteger and: [ (next := self next) notNil ] ] whileTrue: [ result add: next ].
	^ result
]

{ #category : #initialization }
SoilScanIterator >> setObjects: aCollection [
	objects := aCollection.
	index := 0
]

{ #category : #enumerating }
SoilScanIterator >> upToEnd [
	| result |
	result := OrderedCollection new.
	[ self atEnd ] whileFalse: [ result add: self next ].
	^ result
]
