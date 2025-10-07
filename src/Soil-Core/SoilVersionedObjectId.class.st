Class {
	#name : #SoilVersionedObjectId,
	#superclass : #SoilObjectId,
	#instVars : [
		'version'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #converting }
SoilVersionedObjectId >> asSoilObjectId [
	^ self as: SoilObjectId 
]

{ #category : #accessing }
SoilVersionedObjectId >> objectId [
	^ self
]

{ #category : #printing }
SoilVersionedObjectId >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ':' << version asString 
]

{ #category : #accessing }
SoilVersionedObjectId >> version [

	^ version
]

{ #category : #accessing }
SoilVersionedObjectId >> version: anObject [

	version := anObject
]
