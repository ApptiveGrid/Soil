Class {
	#name : #SoilObjectTable,
	#superclass : #Object,
	#instVars : [
		'objects',
		'index'
	],
	#category : #'Soil-Serializer'
}

{ #category : #'collection-compat' }
SoilObjectTable >> add: anObject [
	^self registerObject: anObject
]

{ #category : #accessing }
SoilObjectTable >> at: anInteger [
	^ objects at: anInteger
]

{ #category : #'collection-compat' }
SoilObjectTable >> identityIndexOf: anObject [
	^self indexOf: anObject
]

{ #category : #initialization }
SoilObjectTable >> indexOf: anObject [

	^ index at: anObject ifAbsent: [ 0 ]
]

{ #category : #initialization }
SoilObjectTable >> initialize [
	objects := OrderedCollection new.
	index := IdentityDictionary new
]

{ #category : #initialization }
SoilObjectTable >> registerObject: anObject [

	index
		at: anObject
		ifAbsentPut: [ objects addLastAndReturnIndex: anObject ]
]

{ #category : #accessing }
SoilObjectTable >> size [
	^ objects size
]
