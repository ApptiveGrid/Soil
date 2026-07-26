Class {
	#name : #SoilCopyingVisitor,
	#superclass : #SoilVisitor,
	#category : #'Soil-Core-Visitor'
}

{ #category : #copying }
SoilCopyingVisitor >> copyAllClusterVersions: aSoilPersistentClusterVersion [
	"copy the (kept) version chain; a single-version object is just a one-element chain"
	aSoilPersistentClusterVersion hasPreviousVersion
		ifFalse: [ ^ self copyClusterVersionChain: { aSoilPersistentClusterVersion } ].
	^ self copyClusterVersionChain:
		((soil objectRepository segmentAt: aSoilPersistentClusterVersion objectId segment)
			allVersionsAt: aSoilPersistentClusterVersion objectId index)
]

{ #category : #copying }
SoilCopyingVisitor >> copyClusterVersionChain: aCollectionOfClusterVersions [
	"Write the kept versions of the chain into the target segment, then run the graph
	traversal (references + indexes) over the kept versions, oldest-to-newest. Subclasses
	steer this via keptVersionsOf:, targetSegmentFor: and copyIndexAt:segment:."
	| kept position |
	kept := self keptVersionsOf: aCollectionOfClusterVersions.
	position := (self targetSegmentFor: kept first objectId segment) copyVersionChain: kept.
	kept reverseDo: [ :cluster |
		cluster references do: [ :reference | self processObjectId: reference ].
		cluster indexIds do: [ :indexId |
			self copyIndexAt: indexId segment: cluster segment ] ].
	^ position
]

{ #category : #copying }
SoilCopyingVisitor >> copyIndexAt: indexId segment: segmentId [
	"Persist the index into the target. Backup rebuilds it in the target repository;
	the GC vacuum handles indexes its own way."
	^ self subclassResponsibility
]

{ #category : #copying }
SoilCopyingVisitor >> keptVersionsOf: aCollectionOfClusterVersions [
	"Which versions of the chain to copy. Default: the whole chain (full history, as
	backup needs). Subclasses that prune (e.g. the GC vacuum) override this."
	^ aCollectionOfClusterVersions
]

{ #category : #copying }
SoilCopyingVisitor >> targetSegmentFor: aSegmentId [
	"The segment reachable objects are copied into (understands copyVersionChain:).
	Backup: the target repository's segment; the GC vacuum: the compaction clone."
	^ self subclassResponsibility
]

{ #category : #visiting }
SoilCopyingVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [
	"Copy every reachable persistent cluster's (kept) version chain into the target."
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	self copyAllClusterVersions: aSoilPersistentClusterVersion.
	^ aSoilPersistentClusterVersion
]
