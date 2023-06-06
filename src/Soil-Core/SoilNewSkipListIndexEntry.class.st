Class {
	#name : #SoilNewSkipListIndexEntry,
	#superclass : #SoilNewIndexEntry,
	#instVars : [
		'maxLevel'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #committing }
SoilNewSkipListIndexEntry >> commitIn: aSoilTransaction [ 
	| index |
	index := SoilSkipList new.
	(aSoilTransaction objectRepository segmentAt: segment)
		registerIndex: index at: id.
	index 
		initializeHeaderPage;
		maxLevel: maxLevel;
		keySize: keySize;
		valueSize: valueSize;
		flush.
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> maxLevel: anInteger [ 
	maxLevel := anInteger
]
