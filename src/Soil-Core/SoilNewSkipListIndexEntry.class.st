Class {
	#name : #SoilNewSkipListIndexEntry,
	#superclass : #SoilNewIndexEntry,
	#instVars : [
		'maxLevel'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewSkipListIndexEntry class >> journalTypeCode [
	^ 10
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> address [
	^ 'index: ', id printString
]

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
SoilNewSkipListIndexEntry >> container [
	^ 'segment #', segment printString
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> maxLevel [

	^ maxLevel
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> maxLevel: anInteger [ 
	maxLevel := anInteger
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilNewSkipListIndexEntry >> readFrom: aStream [ 
	| idSize |
	super readFrom: aStream.
	idSize := aStream next.
	id := (aStream next: idSize) asString.
	segment := aStream nextLengthEncodedInteger.
	maxLevel := aStream nextLengthEncodedInteger.
	keySize := aStream nextLengthEncodedInteger.
	valueSize := aStream nextLengthEncodedInteger
]

{ #category : #accessing }
SoilNewSkipListIndexEntry >> value [ 
	^ 'maxLevel=', maxLevel printString, ',keySize=', keySize printString,',valueSize=', valueSize printString
]

{ #category : #writing }
SoilNewSkipListIndexEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: segment;
		nextPutLengthEncodedInteger: maxLevel;
		nextPutLengthEncodedInteger: keySize;
		nextPutLengthEncodedInteger: valueSize
]
