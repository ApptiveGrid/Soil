Class {
	#name : #SoilNewBTreeListIndexEntry,
	#superclass : #SoilNewIndexEntry,
	#category : #'Soil-Core-Journal'
}

{ #category : #committing }
SoilNewBTreeListIndexEntry >> commitIn: aSoilTransaction [

	| index indexManager |
	indexManager := (aSoilTransaction segmentAt: segment) indexManager.
	index := SoilBTree new
		path: (indexManager pathFor: id);
		initializeFilesystem;
		initializeHeaderPage;
		keySize: keySize;
		valueSize: valueSize;
		flush.
	indexManager at: id put: index
]
