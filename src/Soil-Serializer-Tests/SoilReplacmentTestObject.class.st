Class {
	#name : #SoilReplacmentTestObject,
	#superclass : #Object,
	#instVars : [
		'onSerialization',
		'object'
	],
	#category : #'Soil-Serializer-Tests'
}

{ #category : #accessing }
SoilReplacmentTestObject >> object: anObject [

	object := anObject
]

{ #category : #accessing }
SoilReplacmentTestObject >> onSerialization: anObject [

	onSerialization := anObject
]

{ #category : #'as yet unclassified' }
SoilReplacmentTestObject >> replaceOnMaterialization: anObject [ 
	onSerialization := false.
	object := anObject 
]

{ #category : #'as yet unclassified' }
SoilReplacmentTestObject >> replaceOnSerialization: anObject [ 
	onSerialization := true.
	object := anObject 
]

{ #category : #'as yet unclassified' }
SoilReplacmentTestObject >> soilMaterializationReplacement [ 
	^ onSerialization 
		ifTrue: [ self ]
		ifFalse: [ object ]
]

{ #category : #'as yet unclassified' }
SoilReplacmentTestObject >> soilSerializationReplacement [ 
	^ onSerialization 
		ifTrue: [ object ]
		ifFalse: [ self ]
]
