Class {
	#name : #SoilUpdateSegmentIndexEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'segmentId',
		'index'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilUpdateSegmentIndexEntry class >> journalTypeCode [ 
	^ 6
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> address [
	^ #objectIndex
]

{ #category : #committing }
SoilUpdateSegmentIndexEntry >> commitIn: aSoilTransaction [ 
	(aSoilTransaction segmentAt: segmentId) 
		lastObjectIndex: index value
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> container [
	^ 'segment #', segmentId asString
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> context [
	^ 'segment #', segmentId asString
]

{ #category : #'as yet unclassified' }
SoilUpdateSegmentIndexEntry >> effect [
	^ index
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> index: anInteger [ 
	index := anInteger 
]

{ #category : #printing }
SoilUpdateSegmentIndexEntry >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' segment: ' 
		<< segmentId asString
		<< ' index: ' 
		<< index asString.
]

{ #category : #'instance creation' }
SoilUpdateSegmentIndexEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	segmentId := (aStream next: (aStream next: 2) asInteger) asInteger.
	index := (aStream next: 8 asInteger) asInteger.
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> segment: aSoilObjectSegment [ 
	segmentId := aSoilObjectSegment id
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> value [ 
	^ index 
]

{ #category : #writing }
SoilUpdateSegmentIndexEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: (segmentId asByteArray size asByteArrayOfSize: 2);
		nextPutAll: segmentId asByteArray;
		nextPutAll: (index asByteArrayOfSize: 8)
]
