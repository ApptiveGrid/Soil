Class {
	#name : #SoilConsistencyVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'lastIndexes',
		'errors'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyVisitor >> check [
	self visit: soil
]

{ #category : #'as yet unclassified' }
SoilConsistencyVisitor >> check: anObject using: aBlock proceed: aBoolean [
	aBlock 
		on: Error 
		do: [ :error | 
			errors at: anObject put: error ]
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
	self 
		check: aPage 
		using: [ aPage validate ] 
		proceed: true
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
	errors := Dictionary new
]

{ #category : #accessing }
SoilConsistencyVisitor >> lastIndexOfSegment: anInteger [ 
	^ lastIndexes 
		at: anInteger 
		ifAbsentPut: [ 
			(soil objectRepository segmentAt: anInteger) lastObjectIndex  ]
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
