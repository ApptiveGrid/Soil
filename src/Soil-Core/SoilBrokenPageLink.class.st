"
Pages of a skip list whose next and previous pointers do not chain: a right pointer whose target does not point back, a pointer that leads to a page too low for its level, a loop, a page that cannot be read, or a tail that the header page does not know.

Where the right pointers of the first level can be walked from the header page to their end, every other link can be made again from them: the order of the pages is theirs, and each page knows its levels. Such a finding offers SoilRebuildSkipListLinks (#rightChainIntact). Where the first level is itself broken, the order of the pages would have to be guessed from their keys, and no repair is offered.
"
Class {
	#name : #SoilBrokenPageLink,
	#superclass : #SoilIndexFinding,
	#instVars : [
		'pageOffset',
		'level',
		'reason',
		'rightChainIntact'
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
		at: #rightChainIntact put: rightChainIntact;
		yourself
]

{ #category : #accessing }
SoilBrokenPageLink >> description [
	^ 'page ', pageOffset printString, ' at level ', level printString, ' of index ', indexId printString, ' of segment ', segment printString, ': ', reason
]

{ #category : #initialization }
SoilBrokenPageLink >> initialize [
	super initialize.
	rightChainIntact := false
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

{ #category : #repairing }
SoilBrokenPageLink >> repairActions [
	^ rightChainIntact 
		ifTrue: [ { SoilRebuildSkipListLinks segment: segment indexId: indexId } ]
		ifFalse: [ #() ]
]

{ #category : #accessing }
SoilBrokenPageLink >> rightChainIntact [
	^ rightChainIntact
]

{ #category : #initialization }
SoilBrokenPageLink >> rightChainIntact: aBoolean [
	rightChainIntact := aBoolean
]
