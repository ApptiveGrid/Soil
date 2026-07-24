Class {
	#name : #SoilObjectRepositoryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #helpers }
SoilObjectRepositoryTest >> keptVersionsIn: aSoil at: objectId [
	^ ((aSoil objectRepository segmentAt: objectId segment) allVersionsAt: objectId index)
		collect: [ :each | each version ]
]

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
SoilObjectRepositoryTest >> testCopyVersionChainUpToReadVersionKeepsAllWhenReaderIsOld [
	"readVersion 1: a reader at 1 still needs v1, so nothing is discardable."
	| oid versions target |
	oid := self threeVersionNestedObjectId.
	versions := (soil objectRepository segmentAt: oid segment) allVersionsAt: oid index.
	target := Soil createOnPath: 'soil-tests-target'.
	[ target objectRepository copyVersionChain: versions upToReadVersion: 1.
	  self assert: (self keptVersionsIn: target at: oid) asArray equals: #(3 2 1) ]
		ensure: [ target close; destroy ]
]

{ #category : #tests }
SoilObjectRepositoryTest >> testCopyVersionChainUpToReadVersionKeepsNeededSuffix [
	"readVersion 2: version 1 was superseded at db version 2, so a reader at 2 no
	longer needs it - keep {v3,v2}, drop v1, and rebuild the truncated chain (I4)."
	| oid versions target kept |
	oid := self threeVersionNestedObjectId.
	versions := (soil objectRepository segmentAt: oid segment) allVersionsAt: oid index.
	self assert: (versions collect: [ :e | e version ]) asArray equals: #(3 2 1).
	target := Soil createOnPath: 'soil-tests-target'.
	[ target objectRepository copyVersionChain: versions upToReadVersion: 2.
	  kept := (target objectRepository segmentAt: oid segment) allVersionsAt: oid index.
	  self assert: (kept collect: [ :e | e version ]) asArray equals: #(3 2).
	  self assert: kept last previousVersionPosition equals: 0.
	  self assert: kept first previousVersionPosition > 0 ]
		ensure: [ target close; destroy ]
]

{ #category : #tests }
SoilObjectRepositoryTest >> testCopyVersionChainUpToReadVersionNilKeepsOnlyCurrent [
	"nil (no open transactions): keep only the current version."
	| oid versions target kept |
	oid := self threeVersionNestedObjectId.
	versions := (soil objectRepository segmentAt: oid segment) allVersionsAt: oid index.
	target := Soil createOnPath: 'soil-tests-target'.
	[ target objectRepository copyVersionChain: versions upToReadVersion: nil.
	  kept := (target objectRepository segmentAt: oid segment) allVersionsAt: oid index.
	  self assert: (kept collect: [ :e | e version ]) asArray equals: #(3).
	  self assert: kept last previousVersionPosition equals: 0 ]
		ensure: [ target close; destroy ]
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

{ #category : #helpers }
SoilObjectRepositoryTest >> threeVersionNestedObjectId [
	"commit versions #v1/#v2/#v3 (db versions 1/2/3) of a nested object; answer its objectId"
	| tx tx2 tx3 oid |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #v2.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx3 := soil newTransaction.
	tx3 root nested label: #v3.
	tx3 markDirty: tx3 root nested.
	tx3 commit.
	tx := soil newTransaction.
	oid := tx objectIdOf: tx root nested.
	tx abort.
	^ oid
]
