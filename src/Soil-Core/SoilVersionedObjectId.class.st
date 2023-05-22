Class {
	#name : #SoilVersionedObjectId,
	#superclass : #SoilObjectId,
	#instVars : [
		'version'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilVersionedObjectId >> version [

	^ version
]

{ #category : #accessing }
SoilVersionedObjectId >> version: anObject [

	version := anObject
]
