Class {
	#name : #SoilRemoveKeyEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'indexId',
		'key',
		'value'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilRemoveKeyEntry class >> journalTypeCode [
	^ 4
]

{ #category : #'as yet unclassified' }
SoilRemoveKeyEntry >> commitIn: transaction [ 
	| index |
	index := (transaction indexes associations 
		detect: [ :each | each key id = indexId ]
		ifNone: [ Error signal: 'shouldnt happen' ]) value.
	self flag: #todo.
	"ifAbsent: should not be used here"
	index removeKey: key ifAbsent: [ ]
]

{ #category : #accessing }
SoilRemoveKeyEntry >> indexId: aString [ 
	indexId := aString
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> value: aString [ 
	value := aString
]

{ #category : #writing }
SoilRemoveKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: indexId asByteArray;
		nextPutAll: key asByteArray ;
		nextPutAll: value asByteArray
]
