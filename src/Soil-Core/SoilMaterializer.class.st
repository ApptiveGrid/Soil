Class {
	#name : #SoilMaterializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'stream',
		'objects'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SoilMaterializer class >> materializeFromBytes: aByteArray [
	^ self new 
		rawStream: aByteArray readStream;
		materialize
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> materialize [
	^ self nextObject
]

{ #category : #reading }
SoilMaterializer >> nextArray: aClass [ 
	| array |
	array := aClass new: self nextLengthEncodedInteger.
	self register: array.
	1 to: array size do: [ :index | array at: index put: self nextObject ].
	^ array
]

{ #category : #accessing }
SoilMaterializer >> nextByte [
	^ stream next
]

{ #category : #reading }
SoilMaterializer >> nextLargePositiveInteger [
	^ self nextLengthEncodedInteger 
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextLengthEncodedInteger [
	| value |
	value := self nextByte.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #'memory scanning' }
SoilMaterializer >> nextObject [ 
	^ (TypeCodeMapping at: self nextByte) soilMaterialize: self 
]

{ #category : #accessing }
SoilMaterializer >> rawStream: aStream [ 
	stream := aStream
]

{ #category : #registry }
SoilMaterializer >> register: anObject [
	objects ifNil: [ objects := OrderedCollection new ].
	objects add: anObject 
]
