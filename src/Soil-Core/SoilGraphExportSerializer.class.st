"
I serialize a cluster whose root a migration of SoilGraphExporter has replaced.

The serializer knows the cluster root by identity: it is written first, and whatever points at it later becomes an internal reference. A migration hands back another object as the root, typically a shallow copy, while an object embedded in the cluster still points at the one that was replaced. I take that one for the root as well, so it is not written a second time.
"
Class {
	#name : #SoilGraphExportSerializer,
	#superclass : #SoilSerializer,
	#instVars : [
		'replacedRoot'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #registry }
SoilGraphExportSerializer >> registerObject: anObject ifAbsent: aBlock [
	"what still points at the root the migration replaced means the root"
	^ super
		registerObject: (anObject == replacedRoot ifTrue: [ clusterRoot ] ifFalse: [ anObject ])
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilGraphExportSerializer >> replacedRoot: anObject [
	replacedRoot := anObject
]
