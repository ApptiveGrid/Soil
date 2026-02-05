Class {
	#name : #SoilObjectHasConcurrentChange,
	#superclass : #SoilError,
	#instVars : [
		'objectId'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilObjectHasConcurrentChange >> messageText [ 
	^ 'object id: ', objectId asString, ' has been changed by another transaction'
]

{ #category : #accessing }
SoilObjectHasConcurrentChange >> objectId [

	^ objectId
]

{ #category : #accessing }
SoilObjectHasConcurrentChange >> objectId: anObject [

	objectId := anObject
]
