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
SoilNewSkipListIndexEntry >> commitIn: soil [

	| pageCache pageCacheManager headerPage |
	pageCacheManager := (soil objectRepository segmentAt: self segment) pageCacheManager.
	pageCache := pageCacheManager createPageCacheWithId: id class: SoilSkipList.
	headerPage := SoilSkipListHeaderPage new
		offset: 1;
		lastPageOffset: 1;
		firstFreePageIndex: 0;
		pageSize: 4096;
		maxLevel: maxLevel;
		initializeLevel: maxLevel;
		keySize: keySize;
		valueSize: valueSize.
	pageCache pageAt: 1 put: headerPage. 
	pageCache flush  .
	"index := SoilSkipList new
		path: (pageCacheManager pathFor: id);
		initializeFilesystem;
		maxLevel: maxLevel;
		keySize: keySize;
		valueSize: valueSize;
		initializeHeaderPage;
		flush."
	pageCacheManager at: id put: pageCache
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
	^ { objectId }
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
		nextPutLengthEncodedInteger: objectId segment;
		nextPutLengthEncodedInteger: maxLevel;
		nextPutLengthEncodedInteger: keySize;
		nextPutLengthEncodedInteger: valueSize
]
