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
SoilPerson >> compositeKey [
	"an attribute made of two parts of fixed width, three bytes of the last name and two of the first name"
	^ (lastName first: 3) asByteArray , (firstName first: 2) asByteArray
]

{ #category : #accessing }
SoilPerson >> firstName [
	^ firstName
]

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

{ #category : #printing }
SoilPerson >> printOn: aStream [
	super printOn: aStream.
	aStream << ' ' << firstName asString << ' ' << lastName asString
]
