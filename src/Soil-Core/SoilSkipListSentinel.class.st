Class {
	#name : #SoilSkipListSentinel,
	#superclass : #Object,
	#instVars : [
		'lower'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilSkipListSentinel class >> lower [
	^ self new 
		beLower
]

{ #category : #'instance creation' }
SoilSkipListSentinel class >> upper [
	^ self new 
		beUpper
]

{ #category : #comparing }
SoilSkipListSentinel >> < anObject [ 
	^ lower
]

{ #category : #converting }
SoilSkipListSentinel >> asByteArrayOfSize: anInteger [ 
	^ lower
		ifTrue: [ 0 asByteArrayOfSize: anInteger ]
		ifFalse: [ ((2 raisedTo: (anInteger * 8)) - 1) asByteArrayOfSize: anInteger  ]
]

{ #category : #'as yet unclassified' }
SoilSkipListSentinel >> beLower [
	lower := true
]

{ #category : #'as yet unclassified' }
SoilSkipListSentinel >> beUpper [
	lower := false
]
