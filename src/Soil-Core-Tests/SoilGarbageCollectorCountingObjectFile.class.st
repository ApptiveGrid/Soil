"
Test support: an object file that counts how often a record is read with its payload, #atPosition:, and how often only its head is, #headAtPosition:. A collect that reads the history it throws away shows in these numbers.
"
Class {
	#name : #SoilGarbageCollectorCountingObjectFile,
	#superclass : #SoilObjectFile,
	#instVars : [
		'payloadReads',
		'headReads'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilGarbageCollectorCountingObjectFile >> atPosition: anInteger [
	payloadReads := self payloadReads + 1.
	^ super atPosition: anInteger
]

{ #category : #accessing }
SoilGarbageCollectorCountingObjectFile >> headAtPosition: anInteger [
	headReads := self headReads + 1.
	^ super headAtPosition: anInteger
]

{ #category : #accessing }
SoilGarbageCollectorCountingObjectFile >> headReads [
	^ headReads ifNil: [ 0 ]
]

{ #category : #accessing }
SoilGarbageCollectorCountingObjectFile >> payloadReads [
	^ payloadReads ifNil: [ 0 ]
]
