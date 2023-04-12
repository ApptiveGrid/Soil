Class {
	#name : #SoilNewKeyEntry,
	#superclass : #SOJournalEntry,
	#instVars : [
		'indexId',
		'key',
		'value'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewKeyEntry class >> journalTypeCode [
	^ 3
]

{ #category : #'as yet unclassified' }
SoilNewKeyEntry >> commitIn: transaction [ 
	| index |
	index := (transaction indexes associations 
		detect: [ :each | each key id = indexId ]
		ifNone: [ Error signal: 'shouldnt happen' ]) value.
	index at: key put: value 
]

{ #category : #accessing }
SoilNewKeyEntry >> indexId: aString [ 
	indexId := aString
]

{ #category : #accessing }
SoilNewKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilNewKeyEntry >> value: aString [ 
	value := aString
]

{ #category : #writing }
SoilNewKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: indexId asByteArray;
		nextPutAll: key asByteArray ;
		nextPutAll: value asByteArray
]
