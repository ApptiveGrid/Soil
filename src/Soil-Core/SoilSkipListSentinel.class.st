Class {
	#name : #SoilSkipListSentinel,
	#superclass : #Object,
	#instVars : [
		'lower',
		'keySize'
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

{ #category : #comparing }
SoilSkipListSentinel >> > anInteger [ 
	^ lower not
]

{ #category : #arithmetic }
SoilSkipListSentinel >> adaptToNumber: anInteger andSend: aString [ 
	^ anInteger perform: aString asSymbol with: self numericValue
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

{ #category : #accessing }
SoilSkipListSentinel >> keySize: anObject [

	keySize := anObject
]

{ #category : #converting }
SoilSkipListSentinel >> numericValue [ 
	^ lower
		ifTrue: [ 0 ]
		ifFalse: [ ((2 raisedTo: (keySize * 8)) - 1) ]
]
