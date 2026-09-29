"
One walk over a database for a list of trackers (SoilTracker), each of which is shown every object id reached, every index and every cluster read, and collects what concerns it.

It opens a transaction only when one of its trackers asks for one, and then one for all of them: what the trackers find has to have been read at one version to fit together. Without such a tracker it reads at its databaseVersion alone, so trackers that only look at the structure on disk run on a copy or in an image without the application's classes as well.
"
Class {
	#name : #SoilTrackingVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'trackers'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilTrackingVisitor >> addTracker: aTracker [
	^ trackers add: aTracker
]

{ #category : #initialization }
SoilTrackingVisitor >> initialize [ 
	super initialize.
	trackers := OrderedCollection new
]

{ #category : #testing }
SoilTrackingVisitor >> needsTransaction [
	^ trackers anySatisfy: [ :each | each needsTransaction ]
]

{ #category : #visiting }
SoilTrackingVisitor >> processObjectId: aSoilObjectId [ 
	trackers do: [ :each | each trackObjectId: aSoilObjectId in: self ].
	^ super processObjectId: aSoilObjectId 
]

{ #category : #api }
SoilTrackingVisitor >> track: aSoil [
	"walk aSoil once for all trackers. A transaction handed in before is used as it is"
	soil := aSoil.
	(transaction isNil and: [ self needsTransaction ])
		ifTrue: [ self visitWithTransaction: aSoil ]
		ifFalse: [ self visit: aSoil ]
]

{ #category : #accessing }
SoilTrackingVisitor >> trackers [
	^ trackers
]

{ #category : #visiting }
SoilTrackingVisitor >> visitDatabaseJournal: aJournal [
	"the journal has a check of its own, SoilJournalConsistencyVisitor"
	^ aJournal
]

{ #category : #visiting }
SoilTrackingVisitor >> visitIndex: anIndex [ 
	trackers do: [ :each | each trackIndex: anIndex in: self ].
	^ super visitIndex: anIndex 
]

{ #category : #visiting }
SoilTrackingVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	trackers do: [ :each | each trackCluster: aSoilPersistentClusterVersion in: self ].
	^ super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]
