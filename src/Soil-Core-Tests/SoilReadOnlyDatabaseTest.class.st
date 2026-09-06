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
SoilReadOnlyDatabaseTest >> damageJournal [
	"cut the tail off the last journal fragment, so the entries after the last
	checkpoint cannot be read to their end"

	| fragment bytes |
	fragment := ((soil path / 'journal') children select: [ :each | each isFile ]) last.
	bytes := fragment binaryReadStream upToEnd.
	fragment delete.
	fragment binaryWriteStreamDo: [ :out |
		out nextPutAll: (bytes first: bytes size - 12) ]
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

{ #category : #running }
SoilReadOnlyDatabaseTest >> writeSecondTransaction [
	"a second commit, so the journal has entries after the first checkpoint"

	| txn |
	txn := soil newTransaction.
	txn root add: #third.
	txn markDirty: txn root.
	txn commit
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testCanRecoverIsFalseWhenReadOnly [
	"the two reasons not to recover are independent: the flag, and the medium"

	soil close.
	self openReadOnly.
	self deny: readOnly canRecover.
	self assert: soil canRecover
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testDamagedDatabaseSignalsRatherThanWriting [
	"recovery writes, so a reader that may not write has to be told - and told
	before anything is written, not from inside a failing write"

	| before |
	self writeSecondTransaction.
	soil close.
	self damageJournal.
	before := self fileSizes.
	readOnly := Soil path: 'soil-tests'.
	readOnly readOnly: true.
	self should: [ readOnly open ] raise: SoilDatabaseNeedsRecovery.
	self assert: self fileSizes equals: before
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testHealthyDatabaseOpensThroughFullOpen [
	"a database closed cleanly has nothing past its last checkpoint, so recovery is
	a no-op and even the full #open touches no file"

	| before txn |
	soil close.
	before := self fileSizes.
	readOnly := Soil path: 'soil-tests'.
	readOnly readOnly: true.
	readOnly open.
	txn := readOnly newReadOnlyTransaction.
	self assert: txn root equals: (OrderedCollection with: #first with: #second).
	txn abort.
	self assert: self fileSizes equals: before
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testRepairingWithWriteAccessThenReopeningReadOnly [
	"the repair is the caller's to make, step by step: open writable so recovery
	runs, close, come back read-only"

	| txn |
	self writeSecondTransaction.
	soil close.
	self damageJournal.
	readOnly := Soil path: 'soil-tests'.
	readOnly open.
	readOnly close.
	readOnly readOnly: true.
	readOnly open.
	self assert: readOnly readOnly.
	self deny: readOnly control stream class equals: SoilLockableStream.
	txn := readOnly newReadOnlyTransaction.
	self assert: txn root equals: (OrderedCollection with: #first with: #second with: #third).
	txn abort
]

{ #category : #tests }
SoilReadOnlyDatabaseTest >> testWritableDatabaseStillRecovers [
	"the ordinary path is untouched: with write access #open recovers as before"

	| recovered txn |
	self writeSecondTransaction.
	soil close.
	self damageJournal.
	recovered := Soil path: 'soil-tests'.
	recovered open.
	txn := recovered newTransaction.
	self assert: txn root equals: (OrderedCollection with: #first with: #second with: #third).
	txn abort.
	recovered close
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
