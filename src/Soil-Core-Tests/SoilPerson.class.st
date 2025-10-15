Class {
	#name : #SoilPerson,
	#superclass : #Object,
	#instVars : [
		'id',
		'lastName',
		'firstName'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilPerson >> firstName: aString [ 
	firstName := aString 
]

{ #category : #accessing }
SoilPerson >> id [
	^ id
]

{ #category : #accessing }
SoilPerson >> id: aString [ 
	id := aString 
]

{ #category : #accessing }
SoilPerson >> lastName [
	^ lastName
]

{ #category : #accessing }
SoilPerson >> lastName: aString [ 
	lastName := aString 
]
