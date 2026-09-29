"
Does the file hold what its format promises: object ids within their segment, index pages that validate. Needs no classes of the application, no materializing and no transaction - it is the check to run on a copy or on a database one does not want to open for work.
"
Class {
	#name : #SoilDatabaseConsistencyTracker,
	#superclass : #SoilConsistencyTracker,
	#instVars : [
		'lastIndexes'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkObjectId: aSoilObjectId in: aVisitor [
	(aSoilObjectId segment > 1) ifTrue: [ 
		Error signal: 'segment cannot be greater than 1' ].
	(aSoilObjectId index > (self lastIndexOfSegment: aSoilObjectId segment in: aVisitor)) ifTrue: [ 
		Error signal: 'index is greater than last index in the segment #', aSoilObjectId segment asString ]
]

{ #category : #initialization }
SoilDatabaseConsistencyTracker >> initialize [ 
	super initialize.
	lastIndexes := Dictionary new
]

{ #category : #accessing }
SoilDatabaseConsistencyTracker >> lastIndexOfSegment: anInteger in: aVisitor [
	^ lastIndexes 
		at: anInteger 
		ifAbsentPut: [ (aVisitor soil objectRepository segmentAt: anInteger) lastObjectIndex ]
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackIndex: anIndex in: aVisitor [
	anIndex newIterator pagesDo: [ :page | 
		self check: page using: [ page validate ] ]
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackObjectId: aSoilObjectId in: aVisitor [
	self 
		check: aSoilObjectId 
		using: [ self checkObjectId: aSoilObjectId in: aVisitor ]
]
