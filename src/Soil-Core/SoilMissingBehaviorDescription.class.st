"
A behavior description that an object refers to and that is not there: the object it names does not exist, or does not have the version asked for, or the chain of its versions cannot be read. Named once for each description, with the first object that was seen to refer to it.
"
Class {
	#name : #SoilMissingBehaviorDescription,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'descriptionId',
		'version',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilMissingBehaviorDescription class >> objectId: aSoilObjectId descriptionId: aDescriptionId version: anInteger reason: aString [
	^ self new
		objectId: aSoilObjectId descriptionId: aDescriptionId version: anInteger reason: aString;
		yourself
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #descriptionId put: descriptionId printString;
		at: #version put: version;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> description [
	^ 'behavior description ', descriptionId printString, ' version ', version printString, ' referred to by ', objectId printString, ': ', reason
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> descriptionId [
	^ descriptionId
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> kind [
	^ #missingBehaviorDescription
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilMissingBehaviorDescription >> objectId: aSoilObjectId descriptionId: aDescriptionId version: anInteger reason: aString [
	objectId := aSoilObjectId.
	descriptionId := aDescriptionId.
	version := anInteger.
	reason := aString
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> reason [
	^ reason
]

{ #category : #accessing }
SoilMissingBehaviorDescription >> version [
	^ version
]
