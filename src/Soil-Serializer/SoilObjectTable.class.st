Class {
	#name : #SoilObjectTable,
	#superclass : #Object,
	#instVars : [
		'lastIndex',
		'index'
	],
	#category : #'Soil-Serializer'
}

{ #category : #api }
SoilObjectTable >> add: anObject [
	index
		at: anObject
		ifAbsentPut: [ lastIndex := lastIndex + 1 ]
]

{ #category : #api }
SoilObjectTable >> identityIndexOf: anObject [
	 ^ index at: anObject ifAbsent: [ 0 ]
]

{ #category : #initialization }
SoilObjectTable >> indexOf: anObject [

	^ index at: anObject ifAbsent: [ 0 ]
]

{ #category : #initialization }
SoilObjectTable >> initialize [
	lastIndex := 0.
	index := IdentityDictionary new
]

{ #category : #accessing }
SoilObjectTable >> size [
	^ lastIndex
]
