Class {
	#name : #SoilRemovedObjectId,
	#superclass : #SoilObjectId,
	#instVars : [
		'removedId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilRemovedObjectId class >> for: aSoilObjectId [

	^self basicNew 
		segment: 0; index: 0;
		removedId: aSoilObjectId;
		yourself 
]

{ #category : #accessing }
SoilRemovedObjectId >> removedId [

	^ removedId
]

{ #category : #accessing }
SoilRemovedObjectId >> removedId: anObject [

	removedId := anObject
]
