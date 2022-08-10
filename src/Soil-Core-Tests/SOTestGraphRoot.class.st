Class {
	#name : #SOTestGraphRoot,
	#superclass : #Object,
	#instVars : [
		'nested'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOTestGraphRoot >> nested [

	^ nested
]

{ #category : #accessing }
SOTestGraphRoot >> nested: anObject [

	nested := anObject
]
