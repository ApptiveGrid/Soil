Class {
	#name : #SoilConsistencyVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'lastIndexes',
		'errors',
		'shouldMaterializeObjects'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyVisitor >> check [
	self visitWithTransaction: soil
]

{ #category : #checking }
SoilConsistencyVisitor >> check: anObject using: aBlock [
	aBlock 
		on: Error 
		do: [ :error | 
			errors at: anObject put: error ]
]

{ #category : #checking }
SoilConsistencyVisitor >> checkBehaviorDescription: objectId [
	| description |
	description := transaction objectWithId: objectId.
	self check: description using: [  
		soil behaviorRegistry 
			nameAt: description behaviorIdentifier 
			ifAbsent: [ Error signal: 'description for ', description behaviorIdentifier asString , ' cannot not be found in identifier index' ] ]
]

{ #category : #checking }
SoilConsistencyVisitor >> checkCluster: cluster [
	self checkObjectId: cluster objectId.
	cluster references do: [ :ref | 
		self checkObjectId: ref ].
	cluster behaviorDescriptions do: [ :description |
		self checkBehaviorDescription: description ].
	shouldMaterializeObjects ifTrue: [  
		self 
			check: cluster 
			using: [ (cluster transaction: transaction) materializeObject ] ]
]

{ #category : #checking }
SoilConsistencyVisitor >> checkObjectId: aSoilObjectId [ 
	(aSoilObjectId segment > 1) ifTrue: [ 
		Error signal: 'segment cannot be greater than 1' ].
	(aSoilObjectId index > (self lastIndexOfSegment: aSoilObjectId segment)) ifTrue: [ 
		Error signal: 'index is greater than last index in the segment #', aSoilObjectId segment asString  ] 
]

{ #category : #checking }
SoilConsistencyVisitor >> checkPage: aPage [ 
	self 
		check: aPage 
		using: [ aPage validate ] 
	
]

{ #category : #checking }
SoilConsistencyVisitor >> checkPagesOfIndex: index [ 
	| iterator |
	iterator := index newIterator.
	iterator pagesDo: [ :page | 
		self checkPage: page  ]
]

{ #category : #initialization }
SoilConsistencyVisitor >> initialize [ 
	super initialize.
	lastIndexes := Dictionary new.
	errors := Dictionary new.
	shouldMaterializeObjects := false
]

{ #category : #accessing }
SoilConsistencyVisitor >> lastIndexOfSegment: anInteger [ 
	^ lastIndexes 
		at: anInteger 
		ifAbsentPut: [ 
			(soil objectRepository segmentAt: anInteger) lastObjectIndex  ]
]

{ #category : #setting }
SoilConsistencyVisitor >> materializeObjects [ 
	shouldMaterializeObjects := true
]

{ #category : #visiting }
SoilConsistencyVisitor >> processIndexValue: aSoilObjectId [ 
	self checkObjectId: aSoilObjectId.
	^ super processIndexValue: aSoilObjectId 
]

{ #category : #accessing }
SoilConsistencyVisitor >> processObjectId: aSoilObjectId [ 
	self checkObjectId: aSoilObjectId.
	super processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilConsistencyVisitor >> visitDatabaseJournal: aJournal [ 

]

{ #category : #visiting }
SoilConsistencyVisitor >> visitIndex: anIndex [ 
	self checkPagesOfIndex: anIndex.
	^ super visitIndex: anIndex 
]

{ #category : #visiting }
SoilConsistencyVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	self checkCluster: aSoilPersistentClusterVersion.
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]
