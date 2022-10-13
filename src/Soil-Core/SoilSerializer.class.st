Class {
	#name : #SoilSerializer,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'rootObject',
		'objects',
		'classes',
		'stream'
	],
	#category : #'Soil-Core'
}

{ #category : #public }
SoilSerializer >> classDescriptionFor: aClass [ 
	classes ifNil: [ classes := Dictionary new  ].
	^ classes 
		at: aClass 
		ifAbsentPut: [ SOClassDescription for: aClass ]
]

{ #category : #writing }
SoilSerializer >> nextPutNil: anUndefinedObject [ 
	stream nextPutByte: 102
]

{ #category : #registry }
SoilSerializer >> register: anObject [
	objects ifNil: [ objects := Set new ].
	(objects includes: anObject) ifTrue: [ self halt ].
	objects add: anObject  
]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	| binaryStream | 
	binaryStream := ByteArray new writeStream.
	stream := SoilMemoryStream on: binaryStream.
	rootObject := anObject.
	rootObject soilSerialize: self.
	stream flush.
	^ binaryStream contents
]
