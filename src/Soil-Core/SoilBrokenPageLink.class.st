"
Pages of a skip list whose next and previous pointers do not chain: a right pointer whose target does not point back, a pointer that leads to a page too low for its level, a loop, or a tail that the header page does not know. It is named, not repaired - which side is right is not something to guess.
"
Class {
	#name : #SoilBrokenPageLink,
	#superclass : #SoilIndexFinding,
	#instVars : [
		'pageOffset',
		'level',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilBrokenPageLink class >> segment: anInteger indexId: anIndexId pageOffset: anOffset level: aLevel reason: aString [
	^ self new
		segment: anInteger indexId: anIndexId;
		pageOffset: anOffset level: aLevel reason: aString;
		yourself
]

{ #category : #accessing }
SoilBrokenPageLink >> asDictionary [
	^ super asDictionary
		at: #pageOffset put: pageOffset;
		at: #level put: level;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilBrokenPageLink >> description [
	^ 'page ', pageOffset printString, ' at level ', level printString, ' of index ', indexId printString, ' of segment ', segment printString, ': ', reason
]

{ #category : #accessing }
SoilBrokenPageLink >> kind [
	^ #brokenPageLink
]

{ #category : #accessing }
SoilBrokenPageLink >> level [
	^ level
]

{ #category : #accessing }
SoilBrokenPageLink >> pageOffset [
	^ pageOffset
]

{ #category : #initialization }
SoilBrokenPageLink >> pageOffset: anOffset level: aLevel reason: aString [
	pageOffset := anOffset.
	level := aLevel.
	reason := aString
]

{ #category : #accessing }
SoilBrokenPageLink >> reason [
	^ reason
]
