"
Cuts the chain of versions of an object after a record, so that the versions before it are no longer reached: the record that is fine is made the oldest version the object has. It is the way out of a chain that cannot be followed (SoilBrokenVersionChain), and it gives the older versions up - a reader at a version that only they can answer finds no version at all. That is why it is not a default.

The records that stay are written again as a chain of their own, newest last, and the index points at the new newest one; the old records are left where they are for the garbage collection to take.
"
Class {
	#name : #SoilCutVersionChain,
	#superclass : #SoilRepairAction,
	#instVars : [
		'segment',
		'index',
		'position'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilCutVersionChain class >> actionName [
	^ #cutVersionChain
]

{ #category : #'instance creation' }
SoilCutVersionChain class >> newFromDictionary: aDictionary [
	^ self
		segment: (aDictionary at: #segment)
		index: (aDictionary at: #index)
		position: (aDictionary at: #position)
]

{ #category : #'instance creation' }
SoilCutVersionChain class >> segment: anInteger index: anIndex position: aPosition [
	^ self new
		segment: anInteger index: anIndex position: aPosition;
		yourself
]

{ #category : #visiting }
SoilCutVersionChain >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitCutVersionChain: self
]

{ #category : #accessing }
SoilCutVersionChain >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #index put: index;
		at: #position put: position;
		yourself
]

{ #category : #accessing }
SoilCutVersionChain >> description [
	^ 'cut the version chain of object ', index printString, ' of segment ', segment printString, ' after the record at position ', position printString, ', giving up the versions before it'
]

{ #category : #accessing }
SoilCutVersionChain >> index [
	^ index
]

{ #category : #accessing }
SoilCutVersionChain >> position [
	^ position
]

{ #category : #accessing }
SoilCutVersionChain >> segment [
	^ segment
]

{ #category : #initialization }
SoilCutVersionChain >> segment: anInteger index: anIndex position: aPosition [
	segment := anInteger.
	index := anIndex.
	position := aPosition
]
