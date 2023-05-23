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
SoilVersionedObjectId >> version [

	^ version
]

{ #category : #accessing }
SoilVersionedObjectId >> version: anObject [

	version := anObject
]
