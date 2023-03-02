Class {
	#name : #SoilSkipListHeaderPage,
	#superclass : #Object,
	#instVars : [
		'startPageIndex'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #initialization }
SoilSkipListHeaderPage >> initialize [ 
	super initialize.
	startPageIndex := 1
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readFrom: aStream [ 
	aStream next.
	startPageIndex := (aStream next: 8) asInteger
]

{ #category : #accessing }
SoilSkipListHeaderPage >> startPageIndex [
	^ startPageIndex
]

{ #category : #accessing }
SoilSkipListHeaderPage >> startPageIndex: anInteger [ 
	startPageIndex := anInteger 
]

{ #category : #writing }
SoilSkipListHeaderPage >> writeOn: aStream [ 
	aStream nextPut: 0.
	aStream nextPutAll: (startPageIndex asByteArrayOfSize: 8).
]
