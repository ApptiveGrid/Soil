"
An object id that points outside the object ids its segment has handed out.
"
Class {
	#name : #SoilObjectIdOutsideSegment,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'reason',
		'lastIndex'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilObjectIdOutsideSegment class >> objectId: aSoilObjectId beyond: aLastIndex [
	"an id whose index is greater than the last one its segment handed out, which is what
	SoilRaiseSegmentIndex can repair"
	^ (self 
		objectId: aSoilObjectId 
		reason: 'index is greater than the last index ', aLastIndex printString, ' of its segment')
			lastIndex: aLastIndex;
			yourself
]

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
SoilObjectIdOutsideSegment >> lastIndex [
	"the last index of its segment, where the id lies beyond it; nil for another reason"
	^ lastIndex
]

{ #category : #accessing }
SoilObjectIdOutsideSegment >> lastIndex: anInteger [
	lastIndex := anInteger
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

{ #category : #repairing }
SoilObjectIdOutsideSegment >> repairActions [
	^ lastIndex 
		ifNil: [ #() ]
		ifNotNil: [ { SoilRaiseSegmentIndex segment: objectId segment index: objectId index } ]
]
