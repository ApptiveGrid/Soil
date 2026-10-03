"
The chain of versions of an object that cannot be followed to its end: a previous version that cannot be read, versions that do not go down, or a chain that returns to a position it has been at. The position is where it breaks. It is named, not repaired - which versions are right is not something to guess.
"
Class {
	#name : #SoilBrokenVersionChain,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'position',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilBrokenVersionChain class >> objectId: aSoilObjectId position: anInteger reason: aString [
	^ self new
		objectId: aSoilObjectId position: anInteger reason: aString;
		yourself
]

{ #category : #accessing }
SoilBrokenVersionChain >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #position put: position;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilBrokenVersionChain >> description [
	^ 'version chain of ', objectId printString, ' breaks at position ', position printString, ': ', reason
]

{ #category : #accessing }
SoilBrokenVersionChain >> kind [
	^ #brokenVersionChain
]

{ #category : #accessing }
SoilBrokenVersionChain >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilBrokenVersionChain >> objectId: aSoilObjectId position: anInteger reason: aString [
	objectId := aSoilObjectId.
	position := anInteger.
	reason := aString
]

{ #category : #accessing }
SoilBrokenVersionChain >> position [
	^ position
]

{ #category : #accessing }
SoilBrokenVersionChain >> reason [
	^ reason
]
