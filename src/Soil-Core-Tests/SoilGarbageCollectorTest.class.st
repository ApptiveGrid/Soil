Class {
	#name : #SoilGarbageCollectorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilGarbageCollectorTest >> countedCollectBy: aVisitorClass chain: aNumberOfVersions readerBehind: aNumberOrNil [
	"how often a collect reads a record with its payload and how often only its head, over
	a database whose nested object has aNumberOfVersions versions, with a reader open that
	many versions behind the newest if aNumberOrNil says so. A fresh database each time.
	Answers { payload reads. head reads }"
	| counting reader |
	self freshSoil.
	self nestedObjectIndexWithVersions: aNumberOfVersions.
	soil checkpoint.
	aNumberOrNil ifNotNil: [ 
		reader := soil newTransactionForVersion: aNumberOfVersions - aNumberOrNil ].
	counting := self installCountingFileIn: soil objectRepository firstSegment.
	[ aVisitorClass new soil: soil; run ]
		ensure: [ reader ifNotNil: [ reader abort ] ].
	^ { counting payloadReads. counting headReads }
]

{ #category : #running }
SoilGarbageCollectorTest >> damageTheHistoryBehindTheNewestVersionAt: index [
	"put a version behind the newest one that has itself as its previous version: a chain
	that never ends, behind a newest version that reads as it did"
	| segment objectFile newest loopPosition damaged repointed |
	segment := soil objectRepository firstSegment.
	objectFile := segment instVarNamed: #objectFile.
	newest := segment basicAt: index.
	loopPosition := objectFile size.
	damaged := newest copyResetPreviousVersion.
	damaged
		previousVersionPosition: loopPosition;
		version: newest version - 1.
	self assert: (objectFile appendBytes: damaged serialize) equals: loopPosition.
	repointed := newest copyResetPreviousVersion.
	repointed previousVersionPosition: loopPosition.
	segment at: index putBytes: repointed serialize.
	segment flushCachedObjectRecords
]

{ #category : #running }
SoilGarbageCollectorTest >> freshSoil [
	soil close.
	soil := (Soil new path: 'soil-gc-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilGarbageCollectorTest >> installCountingFileIn: aSegment [
	"the object file of aSegment is replaced by one that counts, over the same stream"
	| original counting |
	original := aSegment instVarNamed: #objectFile.
	counting := SoilGarbageCollectorCountingObjectFile new.
	SoilObjectFile allInstVarNames do: [ :name |
		counting instVarNamed: name put: (original instVarNamed: name) ].
	aSegment objectFile: counting.
	^ counting
]

{ #category : #running }
SoilGarbageCollectorTest >> keptAfterACollectBy: aVisitorClass chain: aNumberOfVersions readerBehind: aNumberOrNil [
	"what is left of the nested object after a collect, over a fresh database: the size of
	the objects file, and the version and the bytes of each version kept"
	| index reader segment versions |
	self freshSoil.
	index := self nestedObjectIndexWithVersions: aNumberOfVersions.
	soil checkpoint.
	aNumberOrNil ifNotNil: [ 
		reader := soil newTransactionForVersion: aNumberOfVersions - aNumberOrNil ].
	[ aVisitorClass new soil: soil; run ]
		ensure: [ reader ifNotNil: [ reader abort ] ].
	segment := soil objectRepository firstSegment.
	versions := segment allVersionsAt: index.
	^ { (segment path / #objects) size.
		versions collect: [ :each | each version ].
		versions collect: [ :each | each bytes ] }
]

{ #category : #running }
SoilGarbageCollectorTest >> nestedObjectIndexWithVersions: aNumberOfVersions [
	"the object index of a nested object that has aNumberOfVersions versions, committed
	one after the other and labelled with their number"
	| tx index |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: 1)).
	tx makeRoot: tx root nested.
	tx commit.
	2 to: aNumberOfVersions do: [ :number |
		tx := soil newTransaction.
		tx root nested label: number.
		tx markDirty: tx root nested.
		tx commit ].
	tx := soil newTransaction.
	index := (tx objectIdOf: tx root nested) index.
	tx abort.
	^ index
]

{ #category : #running }
SoilGarbageCollectorTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-gc-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilGarbageCollectorTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testACollectDoesNotReadAChainDamagedBehindTheKeptVersions [
	"a chain that ends in itself is history nobody needs when no reader is open: the collect
	does not read it, and drops it. The way that reads the whole chain says it is damaged,
	and so does the walk of a reader that needs the history behind the newest version."
	| index reader tx |
	index := self nestedObjectIndexWithVersions: 5.
	soil checkpoint.
	self damageTheHistoryBehindTheNewestVersionAt: index.
	self 
		should: [ SoilGarbageCollectorWholeChainVisitor new soil: soil; run ] 
		raise: SoilDatabaseIsInconsistent.
	reader := soil newTransactionForVersion: 1.
	[ self should: [ soil garbageCollect ] raise: SoilDatabaseIsInconsistent ]
		ensure: [ reader abort ].
	soil garbageCollect.
	self assert: (soil objectRepository firstSegment allVersionsAt: index) size equals: 1.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: 5 ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testACollectKeepsWhatTheWholeChainWayKept [
	"reading only the kept versions changes what is read, not what is kept: the objects
	file and the versions in it come out the same as when the whole chain is read and cut"
	{ nil. 5 } do: [ :behind |
		self 
			assert: (self keptAfterACollectBy: SoilGarbageCollectVisitor chain: 20 readerBehind: behind)
			equals: (self keptAfterACollectBy: SoilGarbageCollectorWholeChainVisitor chain: 20 readerBehind: behind) ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testACollectReadsNoMoreForALongChainThanForAShortOne [
	"the history behind the version that is kept is not read: a chain of 50 versions costs
	the collect the same reads as one of 3. The way that reads the whole chain shows what
	the count counts: it reads more the longer the chain is"
	| short long wholeShort wholeLong |
	short := self countedCollectBy: SoilGarbageCollectVisitor chain: 3 readerBehind: nil.
	long := self countedCollectBy: SoilGarbageCollectVisitor chain: 50 readerBehind: nil.
	self assert: long equals: short.
	wholeShort := self countedCollectBy: SoilGarbageCollectorWholeChainVisitor chain: 3 readerBehind: nil.
	wholeLong := self countedCollectBy: SoilGarbageCollectorWholeChainVisitor chain: 50 readerBehind: nil.
	self assert: wholeLong first > wholeShort first.
	self assert: long first < wholeLong first
]

{ #category : #tests }
SoilGarbageCollectorTest >> testACollectWithAnOpenReaderReadsOnlyDownToTheVersionItNeeds [
	"a reader 3 versions behind the newest needs 4 versions of the chain, and the collect
	reads those and not the history behind them, however long the chain is"
	| short long withoutReader |
	short := self countedCollectBy: SoilGarbageCollectVisitor chain: 6 readerBehind: 3.
	long := self countedCollectBy: SoilGarbageCollectVisitor chain: 50 readerBehind: 3.
	self assert: long equals: short.
	withoutReader := self countedCollectBy: SoilGarbageCollectVisitor chain: 50 readerBehind: nil.
	self assert: long first > withoutReader first.
	self assert: long second > withoutReader second
]

{ #category : #tests }
SoilGarbageCollectorTest >> testCollectOfALongChainKeepsTheNewestVersion [
	"no reader is open: of 50 versions the newest stays, and reads as it did"
	| index tx |
	index := self nestedObjectIndexWithVersions: 50.
	soil checkpoint.
	self assert: (soil objectRepository firstSegment allVersionsAt: index) size equals: 50.
	soil garbageCollect.
	self assert: (soil objectRepository firstSegment allVersionsAt: index) size equals: 1.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: 50 ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectCurtailedClosesTheClones [
	"deleting the clone directory is not enough: the files inside have to be closed
	first. On POSIX an open file is removed anyway and only the handle leaks, so
	the deletion alone looks like it worked"

	| tx visitor |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	soil checkpoint.
	visitor := SoilGarbageCollectorFailingVisitor new soil: soil; yourself.
	[ visitor run ] on: Error do: [ :error | ].
	(visitor instVarNamed: 'clones') valuesDo: [ :clone |
		self deny: (clone instVarNamed: 'objectFile') isOpen.
		self deny: (clone instVarNamed: 'indexFile') isOpen ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectCurtailedLeavesDatabaseIntact [
	"if the collect fails mid-run (injected during the copy phase, after clones are built),
	ifCurtailed deletes the clones and the original database is untouched."
	| tx clonePath |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	soil checkpoint.
	clonePath := soil objectRepository firstSegment path, #gc.
	[ SoilGarbageCollectorFailingVisitor new soil: soil; run ]
		on: Error do: [ :e | ].
	self deny: clonePath exists.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: #kept ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectDropsUnreachableObject [
	"an object no longer reachable from root is not copied into the compacted segment."
	| tx dead deadOid tx2 |
	tx := soil newTransaction.
	dead := SoilTestNestedObject new label: #dead.
	tx makeRoot: dead.
	tx root: (Dictionary new at: #dead put: dead; yourself).
	tx commit.
	tx := soil newTransaction.
	deadOid := tx objectIdOf: (tx root at: #dead).
	tx abort.
	tx2 := soil newTransaction.
	tx2 root removeKey: #dead.
	tx2 markDirty: tx2 root.
	tx2 commit.
	soil checkpoint.
	self assert: (soil objectRepository firstSegment basicAt: deadOid index ifAbsent: [ nil ]) notNil.
	soil garbageCollect.
	self assert: (soil objectRepository firstSegment basicAt: deadOid index ifAbsent: [ #gone ]) equals: #gone
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectKeepsCurrentVersionAndReclaimsOldVersions [
	"no open reader: the current version stays readable, the superseded version is
	dropped, and the objects file shrinks."
	| tx tx2 sizeBefore oid |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #v2.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx := soil newTransaction.
	oid := tx objectIdOf: tx root nested.
	tx abort.
	soil checkpoint.
	sizeBefore := (soil objectRepository firstSegment path / #objects) size.
	self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 2.
	soil garbageCollect.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: #v2 ] ensure: [ tx abort ].
	self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 1.
	self assert: (soil objectRepository firstSegment path / #objects) size < sizeBefore
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectKeepsVersionsAnOpenReaderNeeds [
	"a reader pinned at an old readVersion must still find its version after the collect."
	| tx tx2 oid readerTx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #v2.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx := soil newTransaction.
	oid := tx objectIdOf: tx root nested.
	tx abort.
	readerTx := soil newTransactionForVersion: 1.
	[ soil garbageCollect.
	  self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 2.
	  self assert: readerTx root nested label equals: #v1 ]
		ensure: [ readerTx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectLeavesNoCloneDirectory [
	"after a successful collect the clone directory has been renamed into place, not left behind."
	| tx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	soil checkpoint.
	soil garbageCollect.
	self deny: (soil objectRepository firstSegment path, #gc) exists
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectPreservesIndexedDictionary [
	"indexes are carried verbatim; the indexed dictionary and its index-only-reachable
	value must still resolve after the collect."
	| tx |
	tx := soil newTransaction.
	tx root: ((SoilIndexedDictionary newWithBackend: SoilSkipList) keySize: 8; maxLevel: 16; yourself).
	tx root at: #foo put: (SoilTestNestedObject new label: #indexed).
	tx commit.
	soil checkpoint.
	soil garbageCollect.
	tx := soil newTransaction.
	[ self assert: (tx root at: #foo) label equals: #indexed ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testGarbageCollectSetsLastGarbageCollect [
	"a successful collect records a fresh timestamp in the metadata (advances past the default)."
	| tx before |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	before := soil metadata lastGarbageCollect.
	soil garbageCollect.
	self assert: soil metadata lastGarbageCollect > before
]

{ #category : #tests }
SoilGarbageCollectorTest >> testKeptVersionsAtAreTheOnesKeptVersionsOfKeeps [
	"one rule: the versions walked by their heads are the ones the rule keeps of the whole
	chain - for no reader, for readers inside the chain, and for one past the newest version"
	| index segment |
	index := self nestedObjectIndexWithVersions: 8.
	soil checkpoint.
	segment := soil objectRepository firstSegment.
	{ nil. 1. 2. 5. 8. 9 } do: [ :readVersion | | expected actual |
		expected := segment 
			keptVersionsOf: (segment allVersionsAt: index) 
			upToReadVersion: readVersion.
		actual := segment keptVersionsAt: index upToReadVersion: readVersion.
		self 
			assert: (actual collect: [ :each | each position ])
			equals: (expected collect: [ :each | each position ]).
		self 
			assert: (actual collect: [ :each | each bytes ])
			equals: (expected collect: [ :each | each bytes ]) ]
]
