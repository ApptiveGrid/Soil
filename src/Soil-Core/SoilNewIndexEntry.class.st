Class {
	#name : #SoilNewIndexEntry,
	#superclass : #SoilIndexJournalEntry,
	#instVars : [
		'keySize',
		'valueSize',
		'uniqueKeys'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #testing }
SoilNewIndexEntry class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilNewIndexEntry
]

{ #category : #accessing }
SoilNewIndexEntry >> address [
	^ 'index: ', id printString
]

{ #category : #accessing }
SoilNewIndexEntry >> keySize [

	^ keySize
]

{ #category : #accessing }
SoilNewIndexEntry >> keySize: anInteger [ 
	keySize := anInteger
]

{ #category : #accessing }
SoilNewIndexEntry >> uniqueKeys [

	^ uniqueKeys
]

{ #category : #accessing }
SoilNewIndexEntry >> uniqueKeys: anObject [

	uniqueKeys := anObject
]

{ #category : #accessing }
SoilNewIndexEntry >> valueSize [

	^ valueSize
]

{ #category : #accessing }
SoilNewIndexEntry >> valueSize: anInteger [ 
	valueSize := anInteger 
]
