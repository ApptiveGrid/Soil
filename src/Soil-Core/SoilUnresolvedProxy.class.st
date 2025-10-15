Class {
	#name : #SoilUnresolvedProxy,
	#superclass : #Object,
	#instVars : [
		'objectId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilUnresolvedProxy class >> objectId: aSoilObjectId [ 
	^ self new 
		objectId: aSoilObjectId 
]

{ #category : #accessing }
SoilUnresolvedProxy >> objectId [

	^ objectId
]

{ #category : #accessing }
SoilUnresolvedProxy >> objectId: anObject [

	objectId := anObject
]
