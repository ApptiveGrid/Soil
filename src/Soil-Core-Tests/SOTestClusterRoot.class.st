Class {
	#name : #SOTestClusterRoot,
	#superclass : #Object,
	#instVars : [
		'nested'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOTestClusterRoot >> nested [

	^ nested
]

{ #category : #accessing }
SOTestClusterRoot >> nested: aSONestedObject [
	nested := aSONestedObject
]
