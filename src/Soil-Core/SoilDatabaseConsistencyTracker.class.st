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
SoilDatabaseConsistencyTracker >> checkSizeOf: anIndex segment: aSoilObjectSegment [
	"The size in the header page is kept counting up and down and can drift from the
	entries that are really there - which hid entries from a list that took its limit
	from it. This names the drift; its repair action recomputes it.

	Header and count are two reads. A commit landing between them on a database in use
	can show a difference that is gone the next moment; on a copy, or a database
	nobody writes to, the result is exact"
	| stored counted |
	stored := anIndex headerPage size.
	counted := anIndex newIterator sizeViaIteration.
	stored = counted ifFalse: [ 
		self report: (SoilIndexSizeDrift 
			segment: aSoilObjectSegment id 
			indexId: anIndex id 
			stored: stored 
			counted: counted) ]
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
SoilDatabaseConsistencyTracker >> trackIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	anIndex newIterator pagesDo: [ :page | 
		[ page validate ] 
			on: Error 
			do: [ :error | 
				self report: (SoilInvalidIndexPage 
					segment: aSoilObjectSegment id 
					indexId: anIndex id 
					pageOffset: page offset 
					reason: error messageText asString) ] ].
	self 
		check: anIndex 
		using: [ self checkSizeOf: anIndex segment: aSoilObjectSegment ]
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackObjectId: aSoilObjectId in: aVisitor [
	self check: aSoilObjectId using: [ | lastIndex |
		(aSoilObjectId segment > 1) ifTrue: [ 
			^ self report: (SoilObjectIdOutsideSegment 
				objectId: aSoilObjectId 
				reason: 'segment cannot be greater than 1') ].
		lastIndex := self lastIndexOfSegment: aSoilObjectId segment in: aVisitor.
		(aSoilObjectId index > lastIndex) ifTrue: [ 
			self report: (SoilObjectIdOutsideSegment 
				objectId: aSoilObjectId 
				reason: 'index is greater than the last index ', lastIndex printString, ' of its segment') ] ]
]
