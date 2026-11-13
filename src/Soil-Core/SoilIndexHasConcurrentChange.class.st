"
Another transaction changed a key of an index that this transaction changes as well: it put, moved or removed it after this transaction had read. Signalled at commit, before the journal is written, by SoilTransaction>>#detectIndexConflicts.

It is a SoilObjectHasConcurrentChange, so whoever retries a commit on a concurrent change retries this one as well. objectId is the value this transaction puts or removes under the key.
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
	^ 'key ', key printString, ' of index ', indexId asString, ' has been changed by another transaction'
]
