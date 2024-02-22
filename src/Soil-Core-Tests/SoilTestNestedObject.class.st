Class {
	#name : 'SoilTestNestedObject',
	#superclass : 'Object',
	#instVars : [
		'reference',
		'label'
	],
	#category : 'Soil-Core-Tests',
	#package : 'Soil-Core-Tests'
}

{ #category : 'accessing' }
SoilTestNestedObject >> label [
	^ label
]

{ #category : 'accessing' }
SoilTestNestedObject >> label: aString [ 
	label := aString
]

{ #category : 'accessing' }
SoilTestNestedObject >> reference [

	^ reference
]

{ #category : 'accessing' }
SoilTestNestedObject >> reference: anObject [

	reference := anObject
]
