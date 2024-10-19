Class {
	#name : #SoilFreePage,
	#superclass : #SoilIndexPage,
	#instVars : [
		'next',
		'pageIndexes'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilFreePage class >> pageCode [ 
	^ 7
]

{ #category : #adding }
SoilFreePage >> addPage: aPage [ 
	pageIndexes add: aPage index.
	dirty := true.
	^ aPage
]

{ #category : #testing }
SoilFreePage >> hasRoom [
	| used |
	used := self headerSize + pageIndexes size * 4 "page index".
	^ used <= (self pageSize - 4 "page index")
]

{ #category : #utilities }
SoilFreePage >> headerSize [ 
	^ super headerSize + 4 "next"
]

{ #category : #initialization }
SoilFreePage >> initialize [ 
	super initialize.
	pageIndexes := SortedCollection new.
	next := 0
		
]

{ #category : #initialization }
SoilFreePage >> initializeInIndex: anIndex [
	pageIndexes := SortedCollection new.
	next := 0
]

{ #category : #accessing }
SoilFreePage >> label [ 
	^ 'free page'
]

{ #category : #initialization }
SoilFreePage >> latestVersion [
	^ 1
]

{ #category : #testing }
SoilFreePage >> needsCleanup [
	^ false
]

{ #category : #accessing }
SoilFreePage >> next [

	^ next
]

{ #category : #accessing }
SoilFreePage >> next: anObject [

	next := anObject
]

{ #category : #accessing }
SoilFreePage >> pageIndexes [
	^ pageIndexes
]

{ #category : #reading }
SoilFreePage >> readFrom: aStream [ 
	| freePagesSize |
	super readFrom: aStream.
	next := (aStream next: 4) asInteger.
	freePagesSize := (aStream next: 2) asInteger.
	1 to: freePagesSize do: [ :n |
		pageIndexes add: (aStream next: 4) asInteger ]
]

{ #category : #writing }
SoilFreePage >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: (next asByteArrayOfSize: 4);
		nextPutAll: (pageIndexes size asByteArrayOfSize: 2).
	pageIndexes do: [ :pageIndex | 
		aStream nextPutAll: (pageIndex asByteArrayOfSize: 4) ]
	
]
