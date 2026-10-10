"
The chain of versions of an object that cannot be followed to its end: a previous version that cannot be read, versions that do not go down, a chain that returns to a position it has been at, or a previous version that is what is left of a record another one was written over. The position is that of the last record that is fine, the one whose link to its previous version cannot be followed. The one repair there is cuts the chain there (SoilCutVersionChain): the older versions are given up, and that is why it is not a default.
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
	^ 'version chain of ', objectId printString, ' cannot be followed past the record at position ', position printString, ': ', reason
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

{ #category : #repairing }
SoilBrokenVersionChain >> repairActions [
	^ { SoilCutVersionChain segment: objectId segment index: objectId index position: position }
]
