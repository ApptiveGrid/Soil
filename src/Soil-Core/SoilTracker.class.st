"
Something a SoilTrackingVisitor carries along its walk over a database. It is shown every object id the walk reaches, every index and every cluster it reads, and collects what concerns it - it does not act on what it finds. Whether it needs a transaction to do that is its own property: a tracker that only looks at the structure on disk needs none, one that materializes objects does.

The hooks do nothing here; a tracker overrides the ones it needs. What a consistency check finds it answers as #findings, which the visitor gathers into a SoilConsistencyReport.
"
Class {
	#name : #SoilTracker,
	#superclass : #Object,
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilTracker >> findings [
	"what the tracker found that goes into a SoilConsistencyReport; most trackers collect
	something else"
	^ #()
]

{ #category : #testing }
SoilTracker >> needsTransaction [
	^ false
]

{ #category : #tracking }
SoilTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
]

{ #category : #tracking }
SoilTracker >> trackIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	"an index does not know its segment; the visitor passes it along"
]

{ #category : #tracking }
SoilTracker >> trackObjectId: aSoilObjectId in: aVisitor [
	"every time the walk reaches aSoilObjectId, through a reference, an index value or
	a behavior description - not only the first time"
]
