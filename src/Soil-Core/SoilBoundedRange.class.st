"
A range of keys given by its first and its last key, both included. It is what a range
over several attribute values is made of, see SoilDerivedKeyLayout>>#rangeFrom:to:.
"
Class {
	#name : #SoilBoundedRange,
	#superclass : #SoilIndexRange,
	#instVars : [
		'firstKey',
		'lastKey'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilBoundedRange class >> firstKey: aByteArray lastKey: anotherByteArray keySize: anInteger [
	^ self new
		setFirstKey: aByteArray lastKey: anotherByteArray keySize: anInteger;
		yourself
]

{ #category : #accessing }
SoilBoundedRange >> firstKey [
	^ firstKey
]

{ #category : #accessing }
SoilBoundedRange >> lastKey [
	^ lastKey
]

{ #category : #initialization }
SoilBoundedRange >> setFirstKey: aByteArray lastKey: anotherByteArray keySize: anInteger [
	firstKey := aByteArray.
	lastKey := anotherByteArray.
	keySize := anInteger
]
