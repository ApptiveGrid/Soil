"
A range of keys given by its first and its last key, like an interval: each end is either
included or not, and either end can be open. It is what a range over several attribute values
is made of, see SoilDerivedKeyLayout>>#rangeFrom:to:.

A key that is nil is open: the range goes on to the first or to the last key there can be. An end
that is not included moves one key inward, so #firstIndexKey and #lastIndexKey, which a reader
positions and stops with, are the first and the last key that belong to the range. A range whose
ends cross is empty.
"
Class {
	#name : #SoilKeyRange,
	#superclass : #SoilIndexRange,
	#instVars : [
		'firstKey',
		'lastKey',
		'includesFirst',
		'includesLast'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilKeyRange class >> firstKey: aByteArray lastKey: anotherByteArray keySize: anInteger [
	"both ends included"
	^ self
		firstKey: aByteArray
		lastKey: anotherByteArray
		keySize: anInteger
		includeFirst: true
		includeLast: true
]

{ #category : #'instance creation' }
SoilKeyRange class >> firstKey: aByteArray lastKey: anotherByteArray keySize: anInteger includeFirst: firstBoolean includeLast: lastBoolean [
	^ self new
		setFirstKey: aByteArray
		lastKey: anotherByteArray
		keySize: anInteger
		includeFirst: firstBoolean
		includeLast: lastBoolean;
		yourself
]

{ #category : #accessing }
SoilKeyRange >> firstIndexKey [
	^ includesFirst
		ifTrue: [ super firstIndexKey ]
		ifFalse: [ super firstIndexKey + 1 ]
]

{ #category : #accessing }
SoilKeyRange >> firstKey [
	^ firstKey ifNil: [ ByteArray new: keySize ]
]

{ #category : #accessing }
SoilKeyRange >> includesFirst [
	^ includesFirst
]

{ #category : #accessing }
SoilKeyRange >> includesLast [
	^ includesLast
]

{ #category : #accessing }
SoilKeyRange >> lastIndexKey [
	^ includesLast
		ifTrue: [ super lastIndexKey ]
		ifFalse: [ super lastIndexKey - 1 ]
]

{ #category : #accessing }
SoilKeyRange >> lastKey [
	^ lastKey ifNil: [ ByteArray new: keySize withAll: 255 ]
]

{ #category : #initialization }
SoilKeyRange >> setFirstKey: aByteArray lastKey: anotherByteArray keySize: anInteger includeFirst: firstBoolean includeLast: lastBoolean [
	firstKey := aByteArray.
	lastKey := anotherByteArray.
	keySize := anInteger.
	includesFirst := firstBoolean.
	includesLast := lastBoolean
]
