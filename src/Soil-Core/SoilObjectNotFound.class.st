Class {
	#name : #SoilObjectNotFound,
	#superclass : #SoilError,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilObjectNotFound >> index [

	^ index
]

{ #category : #accessing }
SoilObjectNotFound >> index: anObject [

	index := anObject
]

{ #category : #accessing }
SoilObjectNotFound >> segment [

	^ segment
]

{ #category : #accessing }
SoilObjectNotFound >> segment: anObject [

	segment := anObject
]
