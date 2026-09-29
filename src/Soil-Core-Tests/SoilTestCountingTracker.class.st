"
A tracker for tests: counts what it is shown
"
Class {
	#name : #SoilTestCountingTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'clusters',
		'indexes'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilTestCountingTracker >> clusters [
	^ clusters
]

{ #category : #accessing }
SoilTestCountingTracker >> indexes [
	^ indexes
]

{ #category : #initialization }
SoilTestCountingTracker >> initialize [ 
	super initialize.
	clusters := OrderedCollection new.
	indexes := OrderedCollection new
]

{ #category : #tracking }
SoilTestCountingTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	clusters add: aSoilPersistentClusterVersion objectId
]

{ #category : #tracking }
SoilTestCountingTracker >> trackIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	indexes add: anIndex
]
