"
Test support: the collect as it was before it read only the versions it keeps - the whole chain of every object read with its payload first, and cut afterwards.
"
Class {
	#name : #SoilGarbageCollectorWholeChainVisitor,
	#superclass : #SoilGarbageCollectVisitor,
	#category : #'Soil-Core-Tests'
}

{ #category : #copying }
SoilGarbageCollectorWholeChainVisitor >> copyAllClusterVersions: aSoilPersistentClusterVersion [
	^ (SoilCopyingVisitor >> #copyAllClusterVersions:)
		valueWithReceiver: self
		arguments: { aSoilPersistentClusterVersion }
]
