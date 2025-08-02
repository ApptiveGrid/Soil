Class {
	#name : #SoilVisitor,
	#superclass : #SoilBasicVisitor,
	#instVars : [
		'toBeProcessed',
		'seen',
		'depthFirst',
		'databaseVersion',
		'soil'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'as yet unclassified' }
SoilVisitor >> beBreadthFirst [ 
	depthFirst := false.
	seen := Set new.
	toBeProcessed := OrderedCollection new
]

{ #category : #'as yet unclassified' }
SoilVisitor >> beDepthFirst [ 
	depthFirst := true.
	seen := nil.
	toBeProcessed := nil
]

{ #category : #accessing }
SoilVisitor >> databaseVersion [
	^ databaseVersion ifNil: [ 
		databaseVersion := soil control databaseVersion  ]
]

{ #category : #initialization }
SoilVisitor >> initialize [ 
	super initialize.
	self beBreadthFirst 
]

{ #category : #api }
SoilVisitor >> processLoop [ 
	| objectId |
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		self visit: (soil objectRepository 
			basicAt: objectId version: self databaseVersion ) ]
]

{ #category : #accessing }
SoilVisitor >> processObjectId: aSoilObjectId [ 
	((aSoilObjectId segment = 0) and: [ aSoilObjectId index = 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ aSoilObjectId ].
	seen add: aSoilObjectId.
	^ depthFirst 
		ifTrue: [
			self visit: (soil objectRepository at: aSoilObjectId).
			aSoilObjectId ]
		ifFalse: [  
			toBeProcessed add: aSoilObjectId ]
]

{ #category : #accessing }
SoilVisitor >> soil [

	^ soil
]

{ #category : #accessing }
SoilVisitor >> soil: anObject [

	soil := anObject
]

{ #category : #visiting }
SoilVisitor >> visitFirstSegment: aSoilObjectSegment [ 
	depthFirst 
		ifTrue: [ self visit: (aSoilObjectSegment at: 1) ] 
		ifFalse: [ self processObjectId: SoilObjectId root ].			
	self visitObjectSegment: aSoilObjectSegment 
]

{ #category : #visiting }
SoilVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self 
			processIndexId: indexId 
			segment: (soil objectRepository segmentAt: aSoilPersistentClusterVersion segment) ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilVisitor >> visitSoil: aSoil [ 
	super visitSoil: aSoil.
	depthFirst ifFalse: [  
		self processLoop ]
]
