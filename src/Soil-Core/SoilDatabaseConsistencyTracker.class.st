"
Does the file hold what its format promises: object ids within their segment, index pages that validate, an index size that matches what the index holds. Needs no classes of the application, no materializing and no transaction - it is the check to run on a copy or on a database one does not want to open for work.
"
Class {
	#name : #SoilDatabaseConsistencyTracker,
	#superclass : #SoilConsistencyTracker,
	#instVars : [
		'lastIndexes',
		'missingDescriptions',
		'presentDescriptions'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilDatabaseConsistencyTracker >> presentDescriptions [
	"the indexes of the behavior descriptions that were looked up and are there"
	^ presentDescriptions
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkDescriptionsOf: someVersions referencedBy: aSoilObjectId in: aVisitor [
	"every behavior description a version refers to is an object in the meta segment"
	someVersions do: [ :version |
		self 
			checkDescriptionsOfVersion: version 
			referencedBy: aSoilObjectId 
			in: aVisitor ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkDescriptionsOfVersion: aVersion referencedBy: aSoilObjectId in: aVisitor [
	"every behavior description the version refers to is an object in the meta segment.
	Whether it has the version asked for takes the classes to read, and is the application
	tracker's. Named once for each description: a missing one is referred to by every
	object of its class.

	Looked up once for each description, found or not. A chain of a million versions
	refers to a handful of descriptions a million times, and every look-up is a read in the
	index file of the meta segment: that was the better part of an hour for one object"
	aVersion behaviorDescriptions do: [ :versioned | | missing |
		(versioned index = 2 or: [ 
			(presentDescriptions includes: versioned index) or: [ 
				missingDescriptions includes: versioned index ] ]) ifFalse: [
			missing := ([ (aVisitor soil objectRepository segmentAt: 0) 
				basicAt: versioned index 
				ifAbsent: [ nil ] ] on: Error do: [ nil ]) isNil.
			missing 
				ifTrue: [ 
					missingDescriptions add: versioned index.
					self report: (SoilMissingBehaviorDescription 
						objectId: aSoilObjectId 
						descriptionId: versioned asSoilObjectId
						version: versioned version 
						reason: 'there is no such object in the meta segment') ]
				ifFalse: [ presentDescriptions add: versioned index ] ] ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkLinksOf: anIndex segment: aSoilObjectSegment [
	"The data pages of a skip list are chained on every level: the right pointer of a
	page leads to a page whose left pointer leads back, and the left pointer of the
	header page holds the last page of the level, as the tail sentinel. Every level is
	walked from the header page to the right, so a pointer that is off, a loop or a
	page too low for its level is named at the page where it shows.

	The first level is walked first: the order of all pages is that of its right pointers,
	and whether it can be walked to its end says whether every other link can be made
	again from it - which each finding tells, so that it is offered a repair only then"
	| first |
	(anIndex isKindOf: SoilBasicSkipList) ifFalse: [ ^ self ].
	first := self faultsOfLinksOf: anIndex level: 1.
	self 
		reportFaults: first value 
		of: anIndex 
		segment: aSoilObjectSegment 
		level: 1 
		rightChainIntact: first key.
	2 to: anIndex headerPage level do: [ :level | 
		self 
			reportFaults: (self faultsOfLinksOf: anIndex level: level) value 
			of: anIndex 
			segment: aSoilObjectSegment 
			level: level 
			rightChainIntact: first key ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> checkLinksOf: anIndex segment: aSoilObjectSegment level: anInteger [
	| faults |
	faults := self faultsOfLinksOf: anIndex level: anInteger.
	self 
		reportFaults: faults value 
		of: anIndex 
		segment: aSoilObjectSegment 
		level: anInteger 
		rightChainIntact: faults key
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

{ #category : #checking }
SoilDatabaseConsistencyTracker >> faultsOfLinksOf: anIndex level: anInteger [
	"whether the right pointers of the level can be walked from the header page to their
	end, -> the faults found on the way, each the offset of the page it shows at -> what is
	wrong. A left pointer that does not lead back is named at the first page where it does
	not, and the walk goes on; a loop, a page that cannot be read and a page too low for the
	level end it"
	| current visited faults tail |
	faults := OrderedCollection new.
	current := anIndex headerPage.
	visited := Set with: current offset.
	[ (current rightAt: anInteger) = 0 ] whileFalse: [ | nextOffset next |
		nextOffset := current rightAt: anInteger.
		(visited includes: nextOffset) ifTrue: [ 
			faults add: current offset -> ('right pointer leads to page ', nextOffset printString, ' again, the chain is a loop').
			^ false -> faults ].
		visited add: nextOffset.
		next := [ anIndex store pageAt: nextOffset ] 
			on: Error 
			do: [ :error | 
				faults add: current offset -> ('right pointer leads to page ', nextOffset printString, ' which cannot be read: ', error messageText asString).
				^ false -> faults ].
		next level < anInteger ifTrue: [ 
			faults add: current offset -> ('right pointer leads to page ', nextOffset printString, ' which has only ', next level printString, ' levels').
			^ false -> faults ].
		((next leftAt: anInteger) = current offset or: [ faults notEmpty ]) ifFalse: [ 
			faults add: nextOffset -> ('left pointer is ', (next leftAt: anInteger) printString, ' but the page to its left is ', current offset printString) ].
		current := next ].
	"the tail sentinel: the header page holds the last page of the level. Where the level has
	no page but the header, it holds 0 if the level was never used, and the header page
	itself if it was and the last page of it has been removed (SoilBasicSkipList>>removePage:
	hands the left pointer of the removed page, which is the header, on to the tail). Both
	are right"
	tail := anIndex headerPage leftAt: anInteger.
	(current offset = anIndex headerPage offset
		ifTrue: [ tail = 0 or: [ tail = anIndex headerPage offset ] ]
		ifFalse: [ tail = current offset ]) ifFalse: [ 
		faults add: anIndex headerPage offset -> ('tail is ', tail printString, ' but the last page of the level is ', current offset printString) ].
	^ true -> faults
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
	lastIndexes := Dictionary new.
	missingDescriptions := Set new.
	presentDescriptions := Set new
]

{ #category : #accessing }
SoilDatabaseConsistencyTracker >> lastIndexOfSegment: anInteger in: aVisitor [
	^ lastIndexes 
		at: anInteger 
		ifAbsentPut: [ (aVisitor soil objectRepository segmentAt: anInteger) lastObjectIndex ]
]

{ #category : #reporting }
SoilDatabaseConsistencyTracker >> reportFaults: someFaults of: anIndex segment: aSoilObjectSegment level: anInteger rightChainIntact: aBoolean [
	someFaults do: [ :each |
		self report: ((SoilBrokenPageLink 
			segment: aSoilObjectSegment id 
			indexId: anIndex id 
			pageOffset: each key 
			level: anInteger 
			reason: each value)
				rightChainIntact: aBoolean;
				yourself) ]
]

{ #category : #checking }
SoilDatabaseConsistencyTracker >> sizesOf: anIndex [
	"the size the header page stores -> the entries the index holds"
	^ anIndex headerPage size -> anIndex newIterator sizeViaIteration
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	"the chain of versions of the object, and the behavior descriptions of every version
	in it - the current one is not the only one a reader can meet. One version at a time:
	an object written at every commit has a chain of a million records, which as a
	collection took more than the two gigabytes the scheduler runs in"
	self check: aSoilPersistentClusterVersion objectId using: [
		self 
			versionsOf: aSoilPersistentClusterVersion 
			in: aVisitor 
			onFault: [ :position :reason |
				self report: (SoilBrokenVersionChain 
					objectId: aSoilPersistentClusterVersion objectId 
					position: position 
					reason: reason) ]
			do: [ :version |
				self 
					checkDescriptionsOfVersion: version 
					referencedBy: aSoilPersistentClusterVersion objectId 
					in: aVisitor ] ]
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
			self report: (SoilObjectIdOutsideSegment objectId: aSoilObjectId beyond: lastIndex) ] ]
]

{ #category : #tracking }
SoilDatabaseConsistencyTracker >> trackUnreadableRecord: aSoilUnreadableRecord in: aVisitor [
	self report: (SoilUnreadableRecordFinding of: aSoilUnreadableRecord)
]
