Class {
	#name : #SOTestNestedObject,
	#superclass : #Object,
	#instVars : [
		'reference',
		'label'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOTestNestedObject >> label [
	^ label
]

{ #category : #accessing }
SOTestNestedObject >> label: aString [
	label := aString
]

{ #category : #accessing }
SOTestNestedObject >> reference [

	^ reference
]

{ #category : #accessing }
SOTestNestedObject >> reference: anObject [

	reference := anObject
]
