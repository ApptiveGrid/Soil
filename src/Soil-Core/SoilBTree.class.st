Class {
	#name : #SoilBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #deleting }
SoilBTree >> destroy [
	path ensureDelete 
]

{ #category : #testing }
SoilBTree >> isRegistered [
	^ path notNil
]

{ #category : #accessing }
SoilBTree >> path [

	^ path
]

{ #category : #accessing }
SoilBTree >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #converting }
SoilBTree >> thePersistentInstance [
	^ self
]
