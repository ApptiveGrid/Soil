"
A behavior description a cluster refers to whose class name the behavior registry does not know.
"
Class {
	#name : #SoilUnknownBehaviorDescription,
	#superclass : #SoilFinding,
	#instVars : [
		'descriptionId',
		'behaviorIdentifier'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilUnknownBehaviorDescription class >> descriptionId: aSoilObjectId behaviorIdentifier: aString [
	^ self new
		descriptionId: aSoilObjectId behaviorIdentifier: aString;
		yourself
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> asDictionary [
	^ super asDictionary
		at: #descriptionId put: descriptionId printString;
		at: #behaviorIdentifier put: behaviorIdentifier asString;
		yourself
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> behaviorIdentifier [
	^ behaviorIdentifier
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> description [
	^ 'behavior description ', descriptionId printString, ' for ', behaviorIdentifier asString, ' cannot be found in the identifier index'
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> descriptionId [
	^ descriptionId
]

{ #category : #initialization }
SoilUnknownBehaviorDescription >> descriptionId: aSoilObjectId behaviorIdentifier: aString [
	descriptionId := aSoilObjectId.
	behaviorIdentifier := aString
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> kind [
	^ #unknownBehaviorDescription
]

{ #category : #accessing }
SoilUnknownBehaviorDescription >> nodeIn: aSoilGraphTracker [
	^ aSoilGraphTracker nodeAt: descriptionId ifAbsent: [ nil ]
]
