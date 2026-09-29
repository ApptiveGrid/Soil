"
A page of an index that does not validate.
"
Class {
	#name : #SoilInvalidIndexPage,
	#superclass : #SoilIndexFinding,
	#instVars : [
		'pageOffset',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilInvalidIndexPage class >> segment: anInteger indexId: anIndexId pageOffset: anOffset reason: aString [
	^ self new
		segment: anInteger indexId: anIndexId;
		pageOffset: anOffset reason: aString;
		yourself
]

{ #category : #accessing }
SoilInvalidIndexPage >> asDictionary [
	^ super asDictionary
		at: #pageOffset put: pageOffset;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilInvalidIndexPage >> description [
	^ 'page ', pageOffset printString, ' of index ', indexId printString, ' of segment ', segment printString, ': ', reason
]

{ #category : #accessing }
SoilInvalidIndexPage >> kind [
	^ #invalidIndexPage
]

{ #category : #accessing }
SoilInvalidIndexPage >> pageOffset [
	^ pageOffset
]

{ #category : #initialization }
SoilInvalidIndexPage >> pageOffset: anOffset reason: aString [
	pageOffset := anOffset.
	reason := aString
]

{ #category : #accessing }
SoilInvalidIndexPage >> reason [
	^ reason
]
