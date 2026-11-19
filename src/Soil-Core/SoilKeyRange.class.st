"
A range of keys given by its first and its last key, like an interval: each end is either
included or not, and either end can be open. It is what a range over several attribute values
is made of, see SoilDerivedKeyLayout>>#rangeFrom:to:.

A key that is nil is open: the range goes on to the first or to the last key there can be. The
bounds are kept as they are, #includesFirst and #includesLast say whether they belong to the range
and #includesKey: compares with them. Keys are ordered, nothing is added to or taken from one. A
range whose ends cross is empty.
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

{ #category : #testing }
SoilKeyRange >> includesKey: aKey [
	| key |
	key := aKey asIndexKeyOfSize: keySize.
	^ (includesFirst
		ifTrue: [ key >= self firstIndexKey ]
		ifFalse: [ key > self firstIndexKey ]) and: [
			includesLast
				ifTrue: [ key <= self lastIndexKey ]
				ifFalse: [ key < self lastIndexKey ] ]
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
