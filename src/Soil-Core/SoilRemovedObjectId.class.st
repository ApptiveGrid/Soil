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

	^self new
		removedId: aSoilObjectId;
		yourself 
]

{ #category : #'instance creation' }
SoilRemovedObjectId class >> new [

	^self basicNew 
		segment: 0; index: 0;
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
