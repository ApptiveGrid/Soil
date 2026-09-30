"
An object id that points outside the object ids its segment has handed out.
"
Class {
	#name : #SoilObjectIdOutsideSegment,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilObjectIdOutsideSegment class >> objectId: aSoilObjectId reason: aString [
	^ self new
		objectId: aSoilObjectId reason: aString;
		yourself
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> description [
	^ 'object id ', objectId printString, ': ', reason
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> kind [
	^ #objectIdOutsideSegment
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilObjectIdOutsideSegment >> objectId: aSoilObjectId reason: aString [
	objectId := aSoilObjectId.
	reason := aString
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> reason [
	^ reason
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> nodeIn: aSoilGraphTracker [
	^ aSoilGraphTracker nodeAt: objectId ifAbsent: [ nil ]
]
