Class {
	#name : #SoilReadOnlyDatabaseTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'readOnly'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #helper }
SoilReadOnlyDatabaseTest class >> classUnderTest [

	^ Soil
]

{ #category : #running }
SoilReadOnlyDatabaseTest >> fileSizes [
	"the size of every file on disk, so a test can show that nothing was written"

	^ (soil path allChildren
		select: [ :each | each isFile ])
			inject: Dictionary new
			into: [ :sizes :each | sizes at: each fullName put: each size; yourself ]
]

{ #category : #running }
SoilReadOnlyDatabaseTest >> openReadOnly [
	"open the same database again, this time for reading only. #basicOpen and not
	#open: recovery is a separate decision and would write."

	readOnly := Soil path: 'soil-tests'.
	readOnly readOnly: true.
	readOnly basicOpen.
	^ readOnly
]

{ #category : #running }
SoilReadOnlyDatabaseTest >> setUp [

	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem;
		close;
		open.
	self writeRoot
]

{ #category : #running }
SoilReadOnlyDatabaseTest >> tearDown [

	readOnly ifNotNil: [ readOnly close ].
	soil ifNotNil: [ soil close ].
	super tearDown
]

{ #category : #running }
SoilReadOnlyDatabaseTest >> writeRoot [

	| txn |
	txn := soil newTransaction.
	txn root: (OrderedCollection with: #first with: #second).
	txn commit
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testCommitLeavesEveryFileUntouched [
	"the seam sits at the file, not at a Soil-side check: a transaction that still
	believes it may write gets as far as the stream and no further"

	| before txn |
	soil close.
	self openReadOnly.
	before := self fileSizes.
	txn := readOnly newTransaction.
	txn root: (OrderedCollection with: #third).
	self should: [ txn commit ] raise: Error.
	self assert: self fileSizes equals: before
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testControlAndMetadataOpenNonWritable [

	soil close.
	self openReadOnly.
	self deny: readOnly control stream class equals: SoilLockableStream.
	self deny: readOnly metadata stream class equals: SoilLockableStream
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testNormalDatabaseStillUsesLockableStreams [
	"guard for the ordinary case: the flag defaults to false and changes nothing"

	self deny: soil readOnly.
	self assert: soil control stream class equals: SoilLockableStream.
	self assert: soil metadata stream class equals: SoilLockableStream
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testReadsBackWhatWasWritten [
	"reading has to reach the segment files, not just the control file"

	| txn |
	soil close.
	self openReadOnly.
	txn := readOnly newReadOnlyTransaction.
	self assert: txn root equals: (OrderedCollection with: #first with: #second).
	txn abort
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testWriteOnAReadOnlyFileFails [

	soil close.
	self openReadOnly.
	self should: [ readOnly control stream nextPutAll: #[ 1 2 3 ] ] raise: Error
]
