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

{ #category : #committing }
SoilUpdateSegmentIndexEntry >> commitIn: aSoilTransaction [ 
	(aSoilTransaction segmentAt: segmentId) 
		lastObjectIndex: index value
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

{ #category : #accessing }
SoilUpdateSegmentIndexEntry >> segment: aSoilObjectSegment [ 
	segmentId := aSoilObjectSegment id
]
