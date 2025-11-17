Class {
	#name : #SoilBasicIndexedCollection,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'segment'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #journal }
SoilBasicIndexedCollection >> segment [
	^ segment ifNil: [
		segment := (transaction objectIdOf: self) segment ]
]
