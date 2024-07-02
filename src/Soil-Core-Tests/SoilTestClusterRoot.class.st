Class {
	#name : #SoilTestClusterRoot,
	#superclass : #Object,
	#instVars : [
		'nested'
	],
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestClusterRoot >> nested [

	^ nested
]

{ #category : #accessing }
SoilTestClusterRoot >> nested: aSONestedObject [ 
	nested := aSONestedObject 
]
