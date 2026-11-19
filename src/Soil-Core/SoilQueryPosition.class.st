"
A place in the result of a SoilQuery: the value of the property and the primary value of the hit
last delivered, or only the primary value for a query without a property. It does not depend on
how the query was planned, it is made of values and not of the keys of an index, so a query that
starts after it reads on at the same place with an index and without. A caller can keep the two
values between requests and build the position again with #attribute:primary: or #primary:.
"
Class {
	#name : #SoilQueryPosition,
	#superclass : #Object,
	#instVars : [
		'attribute',
		'primary'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilQueryPosition class >> attribute: anAttributeValue primary: aPrimaryValue [
	^ self new
		setAttribute: anAttributeValue primary: aPrimaryValue;
		yourself
]

{ #category : #'instance creation' }
SoilQueryPosition class >> primary: aPrimaryValue [
	^ self attribute: nil primary: aPrimaryValue
]

{ #category : #comparing }
SoilQueryPosition >> = anotherPosition [
	^ self class == anotherPosition class
		and: [ attribute = anotherPosition attribute and: [ primary = anotherPosition primary ] ]
]

{ #category : #accessing }
SoilQueryPosition >> attribute [
	"the value of the property of the hit, nil for a query without a property"
	^ attribute
]

{ #category : #comparing }
SoilQueryPosition >> hash [
	^ attribute hash bitXor: primary hash
]

{ #category : #accessing }
SoilQueryPosition >> primary [
	^ primary
]

{ #category : #printing }
SoilQueryPosition >> printOn: aStream [
	super printOn: aStream.
	aStream << ' ' << attribute printString << ' / ' << primary printString
]

{ #category : #initialization }
SoilQueryPosition >> setAttribute: anAttributeValue primary: aPrimaryValue [
	attribute := anAttributeValue.
	primary := aPrimaryValue
]
