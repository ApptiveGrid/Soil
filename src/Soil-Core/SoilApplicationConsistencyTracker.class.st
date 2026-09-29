"
Does the content fit the model that wrote it: every behavior description of a cluster can be found in the behavior registry, and - when asked to, because it is expensive - every cluster materializes with the classes of this image. Needs a transaction and the loaded classes; it answers whether this application can work with this file.
"
Class {
	#name : #SoilApplicationConsistencyTracker,
	#superclass : #SoilConsistencyTracker,
	#instVars : [
		'shouldMaterializeObjects'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilApplicationConsistencyTracker >> checkBehaviorDescription: aSoilObjectId in: aVisitor [
	self check: aSoilObjectId using: [ | description |
		description := aVisitor transaction objectWithId: aSoilObjectId.
		aVisitor soil behaviorRegistry 
			nameAt: description behaviorIdentifier 
			ifAbsent: [ Error signal: 'description for ', description behaviorIdentifier asString , ' cannot be found in the identifier index' ] ]
]

{ #category : #initialization }
SoilApplicationConsistencyTracker >> initialize [ 
	super initialize.
	shouldMaterializeObjects := false
]

{ #category : #settings }
SoilApplicationConsistencyTracker >> materializeObjects [ 
	shouldMaterializeObjects := true
]

{ #category : #testing }
SoilApplicationConsistencyTracker >> needsTransaction [
	^ true
]

{ #category : #tracking }
SoilApplicationConsistencyTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	aSoilPersistentClusterVersion behaviorDescriptions do: [ :description |
		self checkBehaviorDescription: description in: aVisitor ].
	shouldMaterializeObjects ifTrue: [  
		self 
			check: aSoilPersistentClusterVersion 
			using: [ (aSoilPersistentClusterVersion transaction: aVisitor transaction) materializeObject ] ]
]
