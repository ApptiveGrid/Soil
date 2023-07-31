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

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> effect [
	^ index
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> index: anInteger [ 
	index := anInteger 
]

{ #category : #'as yet unclassified' }
SoilUpdateSegmentIndexEntry >> objectIds [
	^ {  }
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
	segmentId := aStream nextLengthEncodedInteger.
	index := aStream nextLengthEncodedInteger 
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> segment: aSoilObjectSegment [ 
	segmentId := aSoilObjectSegment id
]

{ #category : #validating }
SoilUpdateSegmentIndexEntry >> validateIn: aSoilTransaction [ 
	 (aSoilTransaction segmentAt: segmentId) 
		validateLastObjectIndex: index 
]

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> value [ 
	^ index 
]

{ #category : #writing }
SoilUpdateSegmentIndexEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutLengthEncodedInteger: segmentId;
		nextPutLengthEncodedInteger: index
]
