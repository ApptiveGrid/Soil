"
A tracker for tests: counts what it is shown
"
Class {
	#name : #SoilTestCountingTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'clusters',
		'indexes',
		'values'
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
	indexes := OrderedCollection new.
	values := Dictionary new
]

{ #category : #tracking }
SoilTestCountingTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	clusters add: aSoilPersistentClusterVersion objectId
]

{ #category : #tracking }
SoilTestCountingTracker >> trackIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	indexes add: anIndex
]

{ #category : #tracking }
SoilTestCountingTracker >> trackValue: aSoilObjectId ofIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	(values at: anIndex id ifAbsentPut: [ OrderedCollection new ]) add: aSoilObjectId
]

{ #category : #accessing }
SoilTestCountingTracker >> valuesOfIndex: anIndexId [
	^ values at: anIndexId ifAbsent: [ #() ]
]
