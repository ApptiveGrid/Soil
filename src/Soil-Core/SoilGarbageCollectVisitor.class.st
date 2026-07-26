Class {
	#name : #SoilGarbageCollectVisitor,
	#superclass : #SoilCopyingVisitor,
	#instVars : [
		'readVersion',
		'clones'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #running }
SoilGarbageCollectVisitor >> carryIndexesInto: cloneSegment from: sourceSegment [
	"indexes map key->objectId (position-independent); heap compaction keeps objectIds
	stable, so copy the index files verbatim into the clone"
	(cloneSegment path / #indexes) ensureDeleteAll.
	(sourceSegment path / #indexes) copyAllTo: (cloneSegment path / #indexes)
]

{ #category : #copying }
SoilGarbageCollectVisitor >> copyIndexAt: indexId segment: segmentId [
	"indexes are carried verbatim per segment (see run); nothing to do per index, and
	the reachability of index values comes from the inherited traversal"
	^ self
]

{ #category : #copying }
SoilGarbageCollectVisitor >> keptVersionsOf: aCollectionOfClusterVersions [
	"the vacuum prunes: keep only versions still needed by the smallest open reader"
	^ (soil objectRepository segmentAt: aCollectionOfClusterVersions first objectId segment)
		keptVersionsOf: aCollectionOfClusterVersions upToReadVersion: readVersion
]

{ #category : #processing }
SoilGarbageCollectVisitor >> processBehaviorDescription: aSoilObjectId [
	"meta segment (behavior descriptions) is left untouched by this vacuum, so do not
	traverse into it (I2 deferred)"
	^ aSoilObjectId
]

{ #category : #running }
SoilGarbageCollectVisitor >> run [
	"quiescent object-heap vacuum: compact each object segment into a clone (reachable,
	gated version chains + verbatim indexes) and atomically swap it in"
	readVersion := soil transactionManager smallestReadVersion.
	clones := Dictionary new.
	soil objectRepository flush.
	[ soil objectRepository segments do: [ :segment | | clone |
		clone := segment makeGCClone.
		clone lastObjectIndex: segment lastObjectIndex.
		self carryIndexesInto: clone from: segment.
		clones at: segment id put: clone ].
	  self processObjectId: SoilObjectId root.
	  self processLoop.
	  soil objectRepository segments do: [ :segment |
		segment replaceWith: (clones at: segment id) ] ]
		ifCurtailed: [ clones valuesDo: [ :clone | clone path ensureDeleteAll ] ]
]

{ #category : #copying }
SoilGarbageCollectVisitor >> targetSegmentFor: aSegmentId [
	^ clones at: aSegmentId
]
