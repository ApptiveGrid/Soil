Class {
	#name : #SoilPerson,
	#superclass : #Object,
	#instVars : [
		'id',
		'lastName'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilPerson >> id [
	^ id
]

{ #category : #accessing }
SoilPerson >> id: aString [ 
	id := aString 
]

{ #category : #accessing }
SoilPerson >> lastName: aString [ 
	lastName := aString 
]
