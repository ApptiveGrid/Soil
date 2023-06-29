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

{ #category : #'instance creation' }
SoilNewBTreeListIndexEntry >> readFrom: aStream [ 
	| idSize |
	super readFrom: aStream.
	idSize := aStream next.
	id := (aStream next: idSize) asString.
	segment := aStream nextLengthEncodedInteger.
	keySize := aStream nextLengthEncodedInteger.
	valueSize := aStream nextLengthEncodedInteger
]

{ #category : #writing }
SoilNewBTreeListIndexEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: segment;
		nextPutLengthEncodedInteger: keySize;
		nextPutLengthEncodedInteger: valueSize
]
