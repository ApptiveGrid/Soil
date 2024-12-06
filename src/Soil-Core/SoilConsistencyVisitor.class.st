Class {
	#name : #SoilConsistencyVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'lastIndexes'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyVisitor >> check [
	self visit: soil 
]

{ #category : #'as yet unclassified' }
SoilConsistencyVisitor >> checkCluster: cluster [
	self checkObjectId: cluster objectId.
	cluster references do: [ :ref | 
		self checkObjectId: ref ]
]

{ #category : #'as yet unclassified' }
SoilConsistencyVisitor >> checkHeaderPage: headerPage [ 
	self shouldBeImplemented.
]

{ #category : #'as yet unclassified' }
SoilConsistencyVisitor >> checkObjectId: aSoilObjectId [ 
	(aSoilObjectId segment > 1) ifTrue: [ 
		Error signal: 'segment cannot be greater than 1' ].
	(aSoilObjectId index > (self lastIndexOfSegment: aSoilObjectId segment)) ifTrue: [ 
		Error signal: 'index is greater than last index in the segment #', aSoilObjectId segment asString  ] 
]

{ #category : #'as yet unclassified' }
SoilConsistencyVisitor >> checkPage: aPage [ 
	aPage validate
]

{ #category : #'as yet unclassified' }
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
]

{ #category : #accessing }
SoilConsistencyVisitor >> lastIndexOfSegment: anInteger [ 
	^ lastIndexes 
		at: anInteger 
		ifAbsentPut: [ 
			(soil objectRepository segmentAt: anInteger) lastObjectIndex  ]
]

{ #category : #visiting }
SoilConsistencyVisitor >> processIndexId: indexId segment: aSegment [  
	| index iterator assoc |
	index := aSegment indexManager 
		at: indexId
		ifAbsent: [ Error signal: 'index not found' ].
	self checkPagesOfIndex: index.
	iterator := index newIterator.
	[ (assoc := iterator nextAssociation) isNil ] whileFalse: [ 
		self checkObjectId: assoc value asSoilObjectId.
		self process: assoc value. ]
]

{ #category : #visiting }
SoilConsistencyVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	self checkCluster: aSoilPersistentClusterVersion.
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]
