Class {
	#name : #SoilNewIndexEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'id',
		'segment',
		'keySize',
		'valueSize'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewIndexEntry class >> journalTypeCode [
	^ 10
]

{ #category : #accessing }
SoilNewIndexEntry >> indexId: aString [ 
	id := aString
]

{ #category : #accessing }
SoilNewIndexEntry >> keySize: anInteger [ 
	keySize := anInteger
]

{ #category : #accessing }
SoilNewIndexEntry >> segment: anInteger [ 
	segment := anInteger
]

{ #category : #accessing }
SoilNewIndexEntry >> valueSize: anInteger [ 
	valueSize := anInteger 
]
