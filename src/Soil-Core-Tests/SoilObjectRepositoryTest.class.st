Class {
	#name : #SoilObjectRepositoryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SoilObjectRepositoryTest >> setUp [ 
	super setUp.
	soil := (Soil new path: 'soil-tests')
		destroy; 
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SoilObjectRepositoryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilObjectRepositoryTest >> testCacheObjectRecordMetrics [
	| txn root segment metrics txn2 |
	soil notificationHandler: SoilMetrics new.
	soil objectRepository cacheSegmentAt: 1 upTo: 1000. 
	txn := soil newTransaction.
	root := txn root: Object new.
	txn commit.
	txn2 := soil newTransaction.
	txn2 root.
	txn2 abort.
	segment := soil objectRepository segmentAt: 1.
	metrics := soil notificationHandler.
	self assert: metrics objectRecordCacheHits equals: 1.
	self assert: metrics objectRecordCacheHitRatio equals: 1
]

{ #category : #tests }
SoilObjectRepositoryTest >> testCacheObjectRecords [
	| txn root segment |
	soil objectRepository cacheSegmentAt: 1 upTo: 1000. 
	txn := soil newTransaction.
	root := txn root: Object new.
	txn commit.
	segment := soil objectRepository segmentAt: 1.
	self assert: segment class equals: SoilCachedObjectSegment.
	self assert: segment cache size equals: 1
]

{ #category : #tests }
SoilObjectRepositoryTest >> testFirstSegment [ 
	self assert: soil objectRepository firstSegment id equals: 1
]

{ #category : #tests }
SoilObjectRepositoryTest >> testFlushCachedObjectRecords [
	| txn root segment |
	soil objectRepository cacheSegmentAt: 1 upTo: 1000. 
	txn := soil newTransaction.
	root := txn root: Object new.
	txn commit.
	segment := soil objectRepository segmentAt: 1.
	self assert: segment class equals: SoilCachedObjectSegment.
	self assert: segment cache size equals: 1.
	segment flushCachedObjectRecords.
	self assert: segment cache size equals: 0.
	
]

{ #category : #tests }
SoilObjectRepositoryTest >> testSegmentCreation [	
	soil objectRepository addNewSegment.
	self assert: ('soil-tests' asFileReference / #segments / '2') exists.
	self assert: soil objectRepository segments size equals: 2.

]

{ #category : #tests }
SoilObjectRepositoryTest >> testSegmentInitializationFromDisk [ 
	soil objectRepository instVarNamed: #segments put: nil.
	('soil-tests' asFileReference / #segments / '1') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '2') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '3') ensureCreateDirectory.
	self assert: soil objectRepository segments size equals: 3.

]
