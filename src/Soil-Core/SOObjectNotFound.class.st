Class {
	#name : #SOObjectNotFound,
	#superclass : #SOError,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SOObjectNotFound >> index [

	^ index
]

{ #category : #accessing }
SOObjectNotFound >> index: anObject [

	index := anObject
]

{ #category : #accessing }
SOObjectNotFound >> segment [

	^ segment
]

{ #category : #accessing }
SOObjectNotFound >> segment: anObject [

	segment := anObject
]
