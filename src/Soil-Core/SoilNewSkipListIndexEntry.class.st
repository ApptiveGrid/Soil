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

	| index indexManager |
	indexManager := (aSoilTransaction segmentAt: segment) indexManager.
	index := SoilSkipList new
		path: (indexManager pathFor: id);
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: maxLevel;
		keySize: keySize;
		valueSize: valueSize;
		flush.
	indexManager at: id put: index
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> maxLevel: anInteger [ 
	maxLevel := anInteger
]
