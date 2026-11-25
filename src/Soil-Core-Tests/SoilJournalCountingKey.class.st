"
A key for tests that counts how often it is compared, so that a test can bound the work a
lookup does instead of timing it.
"
Class {
	#name : #SoilJournalCountingKey,
	#superclass : #Object,
	#instVars : [
		'number'
	],
	#classInstVars : [
		'comparisons'
	],
	#category : #'Soil-Core-Tests-Journal'
}

{ #category : #accessing }
SoilJournalCountingKey class >> comparisons [
	^ comparisons ifNil: [ 0 ]
]

{ #category : #private }
SoilJournalCountingKey class >> countComparison [
	comparisons := self comparisons + 1
]

{ #category : #'instance creation' }
SoilJournalCountingKey class >> number: anInteger [
	^ self new
		number: anInteger;
		yourself
]

{ #category : #initialization }
SoilJournalCountingKey class >> resetComparisons [
	comparisons := 0
]

{ #category : #comparing }
SoilJournalCountingKey >> = anObject [
	self class countComparison.
	^ anObject class == self class and: [ number = anObject number ]
]

{ #category : #comparing }
SoilJournalCountingKey >> hash [
	^ number hash
]

{ #category : #accessing }
SoilJournalCountingKey >> number [
	^ number
]

{ #category : #accessing }
SoilJournalCountingKey >> number: anInteger [
	number := anInteger
]
