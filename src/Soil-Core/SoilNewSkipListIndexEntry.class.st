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

{ #category : #committing }
SoilNewSkipListIndexEntry >> commitIn: soil recovery: aBoolean [

	| index indexManager |
	indexManager := (soil objectRepository segmentAt: segment) indexManager.
	"if the index is already open (e.g. repeated commits of the same new index via
	commitAndContinue) reuse it instead of opening the same file a second time,
	which fails on Windows"
	(indexManager indexes at: id ifAbsent: [ nil ]) ifNotNil: [ :existing | ^ existing ].
	index := SoilSkipList new
		path: (indexManager pathFor: id);
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: maxLevel;
		keySize: keySize;
		valueSize: valueSize;
		uniqueKeys: uniqueKeys;
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
	valueSize := aStream nextLengthEncodedInteger.
	uniqueKeys := aStream next == 1
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
		nextPutLengthEncodedInteger: valueSize;
		nextPut: (uniqueKeys ifTrue: [ 1 ] ifFalse: [ 0 ])
]
