"
Does the file hold what its format promises: object ids within their segment, index pages that validate, an index size that matches what the index holds. Needs no classes of the application, no materializing and no transaction - it is the check to run on a copy or on a database one does not want to open for work.
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

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkSizeOf: anIndex [
	"The size in the header page is kept counting up and down and can drift from the
	entries that are really there - which hid entries from a list that took its limit
	from it. This names the drift; SoilIndex>>recomputeSize is the repair.

	Header and count are two reads. A commit landing between them on a database in use
	can show a difference that is gone the next moment; on a copy, or a database
	nobody writes to, the result is exact"
	| stored counted |
	stored := anIndex headerPage size.
	counted := anIndex newIterator sizeViaIteration.
	stored = counted ifFalse: [ 
		Error signal: 'index ', anIndex id printString, ' says it holds ', stored printString, 
			' entries and holds ', counted printString ]
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
		self check: page using: [ page validate ] ].
	self check: anIndex using: [ self checkSizeOf: anIndex ]
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackObjectId: aSoilObjectId in: aVisitor [
	self 
		check: aSoilObjectId 
		using: [ self checkObjectId: aSoilObjectId in: aVisitor ]
]
