"
Carries out the repair actions a person chose (SoilRepairAction), at the places they name and nowhere else - no walk over the database, what a finding names is already where to go. It writes, so it only runs where writing is allowed, and it is started by a person.

An action that fails is kept with its error and the others go on; the checkpoint at the end writes what was repaired. Whether a finding is gone is for the next check to say, not for this visitor.
"
Class {
	#name : #SoilRepairVisitor,
	#superclass : #SoilBasicVisitor,
	#instVars : [
		'soil',
		'repaired',
		'failed'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'instance creation' }
SoilRepairVisitor class >> on: aSoil [
	^ self new
		soil: aSoil;
		yourself
]

{ #category : #accessing }
SoilRepairVisitor >> failed [
	"the actions that failed, each with the text of its error"
	^ failed
]

{ #category : #initialization }
SoilRepairVisitor >> initialize [
	super initialize.
	repaired := OrderedCollection new.
	failed := OrderedCollection new
]

{ #category : #api }
SoilRepairVisitor >> repair: aCollectionOfRepairActions [
	aCollectionOfRepairActions do: [ :each |
		[ self visit: each.
		  repaired add: each ]
			on: Error
			do: [ :error | failed add: each -> error messageText asString ] ].
	repaired ifNotEmpty: [ soil checkpoint ]
]

{ #category : #accessing }
SoilRepairVisitor >> repaired [
	^ repaired
]

{ #category : #accessing }
SoilRepairVisitor >> soil: aSoil [
	soil := aSoil
]

{ #category : #visiting }
SoilRepairVisitor >> visitCutVersionChain: aRepairAction [
	"the versions from the newest down to the record the action names, as they lie in
	the file, written again as a chain that ends there. A chain that does not lead to
	that record any more - it was cut or changed since the check - is not touched"
	| segment record kept positions |
	segment := soil objectRepository segmentAt: aRepairAction segment.
	record := (segment basicAt: aRepairAction index) objectId: (SoilObjectId segment: aRepairAction segment index: aRepairAction index); yourself.
	kept := OrderedCollection with: record.
	positions := Set with: record position.
	[ record position = aRepairAction position ] whileFalse: [
		record hasPreviousVersion ifFalse: [ 
			^ Error signal: 'the chain does not lead to the record at position ', aRepairAction position printString ].
		(positions includes: record previousVersionPosition) ifTrue: [ 
			^ Error signal: 'the chain returns to position ', record previousVersionPosition printString, ' before the record at position ', aRepairAction position printString ].
		positions add: record previousVersionPosition.
		record := (segment recordAtPosition: record previousVersionPosition) objectId: kept first objectId; yourself.
		kept add: record ].
	segment copyVersionChain: kept.
	segment flushCachedObjectRecords
]

{ #category : #visiting }
SoilRepairVisitor >> visitRaiseSegmentIndex: aRepairAction [
	"the id the action names, or the highest the segment has records for if that is
	higher - raised to the id alone it would hand out indexes that exist. It never
	lowers the index, so the actions of several ids can come in any order"
	| segment |
	segment := soil objectRepository segmentAt: aRepairAction segment.
	segment updateLastObjectIndex: (aRepairAction index max: segment highestUsedObjectIndex)
]

{ #category : #visiting }
SoilRepairVisitor >> visitRebuildSkipListLinks: aRepairAction [
	"on the index as its segment holds it, like #visitRecomputeIndexSize:. The pages in the
	order of the first level's right pointers; a loop or a page that is not there ends it
	with an error before anything is changed. A level holds the pages that have it, the
	header page first - which has every level"
	| index header pages current visited |
	index := aRepairAction indexIn: soil.
	header := index headerPage.
	pages := OrderedCollection with: header.
	visited := Set with: header offset.
	current := header.
	[ (current rightAt: 1) = 0 ] whileFalse: [ | nextOffset |
		nextOffset := current rightAt: 1.
		(visited includes: nextOffset) ifTrue: [ 
			^ Error signal: 'the first level is a loop at page ', nextOffset printString ].
		visited add: nextOffset.
		current := index store pageAt: nextOffset.
		pages add: current ].
	1 to: header level do: [ :level | | atLevel |
		atLevel := pages select: [ :each | each level >= level ].
		atLevel withIndexDo: [ :page :position |
			page rightAt: level put: (position < atLevel size 
				ifTrue: [ (atLevel at: position + 1) offset ] 
				ifFalse: [ 0 ]).
			position > 1 ifTrue: [ page leftAt: level put: (atLevel at: position - 1) offset ] ].
		"the tail: the last page of the level; of a level with no page but the header what it
		holds already, if it is 0 or the header itself, both of which are right"
		atLevel size > 1
			ifTrue: [ header leftAt: level put: atLevel last offset ]
			ifFalse: [ 
				((header leftAt: level) = 0 or: [ (header leftAt: level) = header offset ]) ifFalse: [ 
					header leftAt: level put: 0 ] ] ].
	pages do: [ :each | 
		index addDirtyPage: each.
		each markForWrite ]
]

{ #category : #visiting }
SoilRepairVisitor >> visitRecomputeIndexSize: aRepairAction [
	"on the index as its segment holds it, never on the copy-on-write layer a
	transaction sees, whose pages would never reach the disk"
	(aRepairAction indexIn: soil) recomputeSize
]
