Class {
	#name : #SOMaterialization,
	#superclass : #FLMaterialization,
	#instVars : [
		'transaction',
		'record'
	],
	#category : #'Soil-Core-Fuel'
}

{ #category : #private }
SOMaterialization >> fileHeaderStep [ 
]

{ #category : #private }
SOMaterialization >> headerStep [
]

{ #category : #private }
SOMaterialization >> postMaterializationStep [
]

{ #category : #materializing }
SOMaterialization >> preMaterializationStep [
]

{ #category : #accessing }
SOMaterialization >> record [
	^ record
]

{ #category : #accessing }
SOMaterialization >> record: aSOObjectRecord [ 
	record := aSOObjectRecord 
]

{ #category : #accessing }
SOMaterialization >> transaction [

	^ transaction
]

{ #category : #accessing }
SOMaterialization >> transaction: anObject [

	transaction := anObject
]
