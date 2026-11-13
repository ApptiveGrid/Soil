"
A transaction removes a key that another transaction has removed or moved away since it was read. Signalled at commit, before the journal is written, by SoilRemoveKeyEntry>>#validateIn:.

It is a SoilObjectHasConcurrentChange, so whoever retries a commit on a concurrent change retries this one as well. objectId is the value the transaction found under the key.
"
Class {
	#name : #SoilIndexHasConcurrentChange,
	#superclass : #SoilObjectHasConcurrentChange,
	#instVars : [
		'indexId',
		'key'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilIndexHasConcurrentChange >> indexId [

	^ indexId
]

{ #category : #accessing }
SoilIndexHasConcurrentChange >> indexId: aString [

	indexId := aString
]

{ #category : #accessing }
SoilIndexHasConcurrentChange >> key [

	^ key
]

{ #category : #accessing }
SoilIndexHasConcurrentChange >> key: anObject [

	key := anObject
]

{ #category : #accessing }
SoilIndexHasConcurrentChange >> messageText [
	^ 'key ', key printString, ' of index ', indexId asString, ' has been removed by another transaction'
]
