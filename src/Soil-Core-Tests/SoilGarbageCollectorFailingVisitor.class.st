Class {
	#name : #SoilGarbageCollectorFailingVisitor,
	#superclass : #SoilGarbageCollectVisitor,
	#category : #'Soil-Core-Tests'
}

{ #category : #testing }
SoilGarbageCollectorFailingVisitor >> keptVersionsOf: aCollectionOfClusterVersions [
	"test support: fail during the copy phase, after clones are built, before replace"
	Error signal: 'injected vacuum failure'
]
