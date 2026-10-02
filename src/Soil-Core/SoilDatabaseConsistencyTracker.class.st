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
SoilDatabaseConsistencyTracker >> checkLinksOf: anIndex segment: aSoilObjectSegment [
	"The data pages of a skip list are chained on every level: the right pointer of a
	page leads to a page whose left pointer leads back, and the left pointer of the
	header page holds the last page of the level, as the tail sentinel. Every level is
	walked from the header page to the right, so a pointer that is off, a loop or a
	page too low for its level is named at the page where it shows"
	(anIndex isKindOf: SoilBasicSkipList) ifFalse: [ ^ self ].
	1 to: anIndex headerPage level do: [ :level | 
		self checkLinksOf: anIndex segment: aSoilObjectSegment level: level ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkLinksOf: anIndex segment: aSoilObjectSegment level: anInteger [
	| current visited |
	current := anIndex headerPage.
	visited := Set with: current offset.
	[ (current rightAt: anInteger) = 0 ] whileFalse: [ | nextOffset next |
		nextOffset := current rightAt: anInteger.
		(visited includes: nextOffset) ifTrue: [ 
			^ self reportLink: current offset of: anIndex segment: aSoilObjectSegment level: anInteger 
				reason: 'right pointer leads to page ', nextOffset printString, ' again, the chain is a loop' ].
		visited add: nextOffset.
		next := anIndex store pageAt: nextOffset.
		next level < anInteger ifTrue: [ 
			^ self reportLink: current offset of: anIndex segment: aSoilObjectSegment level: anInteger 
				reason: 'right pointer leads to page ', nextOffset printString, ' which has only ', next level printString, ' levels' ].
		(next leftAt: anInteger) = current offset ifFalse: [ 
			^ self reportLink: nextOffset of: anIndex segment: aSoilObjectSegment level: anInteger 
				reason: 'left pointer is ', (next leftAt: anInteger) printString, ' but the page to its left is ', current offset printString ].
		current := next ].
	"the tail sentinel: the header page holds the last page of the level, or 0 where the level is empty"
	(anIndex headerPage leftAt: anInteger) = (current offset = anIndex headerPage offset ifTrue: [ 0 ] ifFalse: [ current offset ]) ifFalse: [ 
		self reportLink: anIndex headerPage offset of: anIndex segment: aSoilObjectSegment level: anInteger 
			reason: 'tail is ', (anIndex headerPage leftAt: anInteger) printString, ' but the last page of the level is ', current offset printString ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkSizeOf: anIndex segment: aSoilObjectSegment [
	"The size in the header page is kept counting up and down and can drift from the
	entries that are really there - which hid entries from a list that took its limit
	from it. This names the drift; its repair action recomputes it.

	Header and count are two reads. A commit landing between them on a database in use
	can show a difference that is gone the next moment, so a difference is read a
	second time and named only if it is still there. On a copy, or a database nobody
	writes to, the second read finds the same"
	| sizes |
	sizes := self sizesOf: anIndex.
	sizes key = sizes value ifTrue: [ ^ self ].
	sizes := self sizesOf: anIndex.
	sizes key = sizes value ifTrue: [ ^ self ].
	self report: (SoilIndexSizeDrift
		segment: aSoilObjectSegment id
		indexId: anIndex id
		stored: sizes key
		counted: sizes value)
]

{ #category : #testing }
SoilDatabaseConsistencyTracker >> hasBrokenChainIn: anIndex segment: aSoilObjectSegment [
	^ findings anySatisfy: [ :each | 
		each class = SoilBrokenPageLink and: [ 
			each segment = aSoilObjectSegment id and: [ each indexId = anIndex id ] ] ]
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

{ #category : #reporting }
SoilDatabaseConsistencyTracker >> reportLink: anOffset of: anIndex segment: aSoilObjectSegment level: anInteger reason: aString [
	self report: (SoilBrokenPageLink 
		segment: aSoilObjectSegment id 
		indexId: anIndex id 
		pageOffset: anOffset 
		level: anInteger 
		reason: aString)
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> sizesOf: anIndex [
	"the size the header page stores -> the entries the index holds"
	^ anIndex headerPage size -> anIndex newIterator sizeViaIteration
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	| before |
	before := findings size.
	self 
		check: anIndex 
		using: [ self checkLinksOf: anIndex segment: aSoilObjectSegment ].
	"the iterator follows the next pointers, so on a chain that is broken it can skip pages
	or never end; the links are named and the pages are left alone"
	findings size > before ifTrue: [ ^ self ].
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
