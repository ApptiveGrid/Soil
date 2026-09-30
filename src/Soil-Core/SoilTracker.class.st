"
Something a SoilTrackingVisitor carries along its walk over a database. It is shown every object id the walk reaches, every index and every cluster it reads, and collects what concerns it - it does not act on what it finds. Whether it needs a transaction to do that is its own property: a tracker that only looks at the structure on disk needs none, one that materializes objects does.

The hooks do nothing here; a tracker overrides the ones it needs.
"
Class {
	#name : #SoilTracker,
	#superclass : #Object,
	#category : #'Soil-Core-Visitor'
}

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
SoilTracker >> trackValue: aSoilObjectId ofIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	"every value the walk reads from anIndex, with the index it came from - which
	#trackObjectId:in: does not say"
]

{ #category : #tracking }
SoilTracker >> trackObjectId: aSoilObjectId in: aVisitor [
	"every time the walk reaches aSoilObjectId, through a reference, an index value or
	a behavior description - not only the first time"
]
