"
Does the content fit the model that wrote it: every behavior description of a cluster can be found in the behavior registry, and - when asked to, because it is expensive - every cluster materializes with the classes of this image. Needs a transaction and the loaded classes; it answers whether this application can work with this file.
"
Class {
	#name : #SoilApplicationConsistencyTracker,
	#superclass : #SoilConsistencyTracker,
	#instVars : [
		'shouldMaterializeObjects',
		'checkedDescriptionVersions'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilApplicationConsistencyTracker >> checkBehaviorDescription: aSoilObjectId in: aVisitor [
	self check: aSoilObjectId using: [ | description |
		description := aVisitor transaction objectWithId: aSoilObjectId.
		aVisitor soil behaviorRegistry 
			nameAt: description behaviorIdentifier 
			ifAbsent: [ 
				self report: (SoilUnknownBehaviorDescription 
					descriptionId: aSoilObjectId 
					behaviorIdentifier: description behaviorIdentifier) ] ]
]

{ #category : #checking }
SoilApplicationConsistencyTracker >> checkDescriptionVersionsOf: someVersions referencedBy: aSoilObjectId in: aVisitor [
	"every behavior description version a version of the object refers to is in the chain
	of that description, and that chain can be read: the registry loads and materializes it
	all. Named once for each description version, with the first object that was seen to
	refer to it - the object is not what is missing"
	someVersions do: [ :version |
		version behaviorDescriptions do: [ :versioned |
			(versioned index = 2 or: [ (checkedDescriptionVersions includes: versioned index -> versioned version) ]) ifFalse: [
				checkedDescriptionVersions add: versioned index -> versioned version.
				[ aVisitor soil behaviorRegistry 
					behaviorDescriptionWithIndex: versioned index 
					andVersion: versioned version 
					transaction: aVisitor transaction ]
					on: Error 
					do: [ :error | 
						self report: (SoilMissingBehaviorDescription 
							objectId: aSoilObjectId 
							descriptionId: versioned asSoilObjectId
							version: versioned version 
							reason: error messageText asString) ] ] ] ]
]

{ #category : #initialization }
SoilApplicationConsistencyTracker >> initialize [ 
	super initialize.
	shouldMaterializeObjects := false.
	checkedDescriptionVersions := Set new
]

{ #category : #settings }
SoilApplicationConsistencyTracker >> materializeObjects [ 
	shouldMaterializeObjects := true
]

{ #category : #checking }
SoilApplicationConsistencyTracker >> materializeOlderVersions: someVersions of: aSoilObjectId in: aVisitor [
	"the versions before the current one, which a reader at an older version meets. The
	records are read whole, as they lie in the file: the chain was followed without their
	payload"
	| segment |
	segment := aVisitor soil objectRepository segmentAt: aSoilObjectId segment.
	someVersions allButFirst do: [ :head |
		[ ((segment recordAtPosition: head position)
			objectId: aSoilObjectId;
			transaction: aVisitor transaction;
			yourself) materializeObject ]
			on: Error 
			do: [ :error | 
				self report: (SoilUnmaterializableVersion 
					objectId: aSoilObjectId 
					version: head version 
					reason: error messageText asString) ] ]
]

{ #category : #testing }
SoilApplicationConsistencyTracker >> needsTransaction [
	^ true
]

{ #category : #tracking }
SoilApplicationConsistencyTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	| versions |
	aSoilPersistentClusterVersion behaviorDescriptions do: [ :description |
		self checkBehaviorDescription: description in: aVisitor ].
	"a chain that cannot be followed is the database tracker's to name; what can be
	followed is checked here"
	versions := self 
		chainOf: aSoilPersistentClusterVersion 
		in: aVisitor 
		onFault: [ :position :reason | ].
	self 
		checkDescriptionVersionsOf: versions 
		referencedBy: aSoilPersistentClusterVersion objectId 
		in: aVisitor.
	shouldMaterializeObjects ifTrue: [  
		[ (aSoilPersistentClusterVersion transaction: aVisitor transaction) materializeObject ]
			on: Error 
			do: [ :error | 
				self report: (SoilUnmaterializableCluster 
					objectId: aSoilPersistentClusterVersion objectId 
					reason: error messageText asString) ].
		self 
			materializeOlderVersions: versions 
			of: aSoilPersistentClusterVersion objectId 
			in: aVisitor ]
]
