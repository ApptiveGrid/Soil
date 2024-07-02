Class {
	#name : #SoilTestGraphRoot,
	#superclass : #Object,
	#instVars : [
		'nested'
	],
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestGraphRoot >> nested [

	^ nested
]

{ #category : #accessing }
SoilTestGraphRoot >> nested: anObject [

	nested := anObject
]
