Class {
	#name : #SoilGraphExporterTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'targetSoil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilGraphExporterTest >> path [
	^ 'soil-tests' asFileReference
]

{ #category : #running }
SoilGraphExporterTest >> setUp [
	super setUp.
	"a target database left behind by a test whose tearDown did not get through would
	make every later test here fail on an existing directory, and the one real failure
	would arrive as a page of them"
	(Soil path: self targetPath) destroy.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #two. #three };
		package: self class package name) install
]

{ #category : #accessing }
SoilGraphExporterTest >> targetPath [
	^ self path, #target
]

{ #category : #running }
SoilGraphExporterTest >> tearDown [
	migrationClass ifNotNil: [
		migrationClass removeFromSystem ].
	super tearDown.
	soil ifNotNil: [
		soil close ].
	targetSoil ifNotNil: [
		targetSoil
			close;
			destroy ]
]

{ #category : #tests }
SoilGraphExporterTest >> testAnOlderExportIsAConflictUnlessItIsAskedFor [
	"The counterpart of testImportOfAShapeTheTargetKnowsAsAnOlderVersion: the same stream,
	the same target, without #acceptExportsFromOlderVersions.

	By default what arrives counts as the newest shape of its class - either the one the
	target already holds or the next version. This stream is neither: the class moved on
	after the export and the target wrote that newer shape, so the arriving one sits behind
	both. It is refused instead of being filed under the version it resembles, and the
	error names both shapes."

	| tx bytes exportTx importer targetTx |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (migrationClass new instVarNamed: #one put: 'native-one'; yourself).
	tx commit.

	tx := soil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself).
	tx commit.
	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #three. #two };
		package: self class package name) install.
	targetTx := targetSoil newTransaction.
	targetTx root: (migrationClass new instVarNamed: #one put: 'newer-one'; yourself).
	targetTx commit.

	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	self should: [ importer import ] raise: SoilBehaviorShapeConflict.
	targetTx abort
]

{ #category : #tests }
SoilGraphExporterTest >> testImportRefusesAStreamOfAnotherFormatVersion [
	"Everything after the version field is read by position, so a stream from another
	version would not fail on its own - it would be read as if it were this one. The
	refusal at the first field is the only place where the difference is still visible."

	| tx bytes exportTx importer targetTx |
	tx := soil newTransaction.
	tx root: (migrationClass new instVarNamed: #one put: 1; yourself).
	tx commit.
	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	"say it is a version this importer does not read"
	bytes
		at: 1 put: 0;
		at: 2 put: SoilGraphExporter formatVersion + 1.

	targetSoil := Soil createOnPath: self targetPath.
	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	self should: [ importer import ] raise: SoilIncompatibleExportFormat.
	targetTx abort
]

{ #category : #tests }
SoilGraphExporterTest >> testExportRefusesAStructureItCannotCarry [
	"The format writes an index as its three sizes and rebuilds a SoilSkipList from them,
	so a BTree dictionary would arrive as something it was not. Nobody has one - this is
	about what the first person to try is told."

	| tx exportTx |
	tx := soil newTransaction.
	tx root: (SoilBTreeDictionary new keySize: 10; yourself).
	tx commit.

	exportTx := soil newTransaction.
	self
		should: [
			ByteArray streamContents: [ :stream |
				(SoilGraphExporter new
					transaction: exportTx;
					addObject: exportTx root;
					yourself)
						stream: stream;
						export ] ]
		raise: SoilUnsupportedError.
	exportTx abort
]

{ #category : #running }
SoilGraphExporterTest >> exportLeavingOutTwoObjects [
	"a graph of three objects where two are left out of the export and named, so that the
	importing side supplies its own objects for them. Answers the stream."

	| tx exportTx root |
	tx := soil newTransaction.
	root := SoilTestGraphRoot new
		nested: (Array
			with: (SoilTestGraphRoot new nested: 'source first'; yourself)
			with: (SoilTestGraphRoot new nested: 'source second'; yourself));
		yourself.
	tx root: root.
	root nested do: [ :each | tx makeRoot: each ].
	tx commit.

	exportTx := soil newTransaction.
	^ [ ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			replaceObject: (exportTx root nested first) as: #first;
			replaceObject: (exportTx root nested second) as: #second;
			yourself)
				stream: stream;
				export ] ]
		ensure: [ exportTx abort ]
]

{ #category : #running }
SoilGraphExporterTest >> targetWithTwoStandIns [
	"two objects in a fresh target database, to stand in for the ones the export left out.
	Answers the transaction to import into, with the stand-ins as its root."

	| tx |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (Array
		with: (SoilTestGraphRoot new nested: 'target first'; yourself)
		with: (SoilTestGraphRoot new nested: 'target second'; yourself)).
	tx root do: [ :each | tx makeRoot: each ].
	tx commit.
	^ targetSoil newTransaction
]

{ #category : #tests }
SoilGraphExporterTest >> testReplacementsArePairedByNameNotByPosition [
	"Two left-out objects, registered on the importing side in the opposite order. What
	pairs them is the name both sides used, so the order they were registered in does not
	matter - pairing them by position, as the import used to, would swap them here and say
	nothing about it."

	| bytes targetTx importer imported |
	bytes := self exportLeavingOutTwoObjects.
	targetTx := self targetWithTwoStandIns.

	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		replaceObject: (targetTx root second) as: #second;
		replaceObject: (targetTx root first) as: #first;
		yourself.
	importer import.
	imported := importer importedObjects first.

	"read before the commit: these are proxies and would fault against a transaction that
	is gone by the time the assertion looks at them"
	self assert: (imported nested first) nested equals: 'target first'.
	self assert: (imported nested second) nested equals: 'target second'.
	targetTx commit
]

{ #category : #tests }
SoilGraphExporterTest >> testImportRefusesAStreamNamingAnUnregisteredReplacement [
	"The export leaves an object out and names it; if the importing side registers nothing
	under that name, there is nothing to point the references at. It is said before the
	import writes anything, and the name is in the message."

	| bytes targetTx |
	bytes := self exportLeavingOutTwoObjects.
	targetTx := self targetWithTwoStandIns.

	self
		should: [
			(SoilGraphImporter new
				transaction: targetTx;
				stream: bytes readStream;
				replaceObject: (targetTx root first) as: #first;
				yourself)
					import ]
		raise: SoilInvalidReplacement.
	targetTx abort
]

{ #category : #tests }
SoilGraphExporterTest >> testExportRefusesTheSameReplacementNameTwice [
	"Two objects under one name would leave the importing side with one of them silently
	unreplaced - the mistake the names are there to prevent."

	| tx exporter |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: 'a'; yourself).
	tx commit.

	tx := soil newTransaction.
	exporter := SoilGraphExporter new
		transaction: tx;
		replaceObject: tx root as: #first;
		yourself.
	self
		should: [ exporter replaceObject: tx root as: #first ]
		raise: SoilInvalidReplacement.
	tx abort
]

{ #category : #running }
SoilGraphExporterTest >> fileSizes [
	"what the source database is made of right now - enough to tell whether anything
	wrote to it"
	^ ((self path allChildren select: #isFile) collect: [ :each |
		   each fullName -> each size ]) asArray sort: [ :a :b | a key <= b key ]
]

{ #category : #tests }
SoilGraphExporterTest >> testExportRunsOnASourceOpenedReadOnly [
	"A copy reads a database another image owns and may not write to it. The export does
	raise clusters whose behavior version is behind - #updateCluster: materializes them
	and serializes them under the current shape - and all of that has to stay inside the
	exporter: what reaches the source is nothing.

	The database here holds two versions of one class, so the first object is genuinely
	behind and #updateCluster: has work to do; the assertion on the file sizes is what
	says the work did not land in the source."

	| bytes exportTx readOnly before targetTx importer imported tx |
	tx := soil newTransaction.
	tx root: (OrderedCollection with: (migrationClass new
		instVarNamed: #one put: 'behind';
		yourself)).
	tx makeRoot: tx root first.
	tx commit.

	"the class moves on and an object of the new shape is written, so the database itself
	carries a newer version of that behavior than the first object does"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #two. #three. #four };
		package: self class package name) install.
	tx := soil newTransaction.
	tx root add: (migrationClass new instVarNamed: #one put: 'current'; yourself).
	tx markDirty: tx root.
	tx makeRoot: tx root last.
	tx commit.
	soil close.
	soil := nil.

	readOnly := Soil path: self path.
	readOnly readOnly: true.
	readOnly open.
	[ before := self fileSizes.
	exportTx := readOnly newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.
	self assert: self fileSizes equals: before ]
		ensure: [ readOnly close ].

	"and what came out is a complete stream"
	targetSoil := Soil createOnPath: self targetPath.
	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	self assert: (imported first instVarNamed: #one) equals: 'behind'.
	self assert: (imported second instVarNamed: #one) equals: 'current'.
	targetTx commit
]

{ #category : #tests }
SoilGraphExporterTest >> testImportIsVisibleToTheTransactionThatRanIt [
	"An import writes its records straight into the segments, and a record is only readable
	by a transaction whose readVersion is at least the version of the record - an imported
	object has no older version to fall back to, so a record stamped too high reads as
	nothing at all.

	Here something else commits into the target after the importing transaction has
	started, which is the normal state of a database in use: the database version moves on
	while the transaction keeps the version it began with. The import has to stay readable
	for that transaction, which is the one that will go on to use what it imported."

	| tx bytes exportTx importer targetTx meanwhile |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: 'exported'; yourself).
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (SoilTestGraphRoot new nested: 'target'; yourself).
	tx commit.

	"the importing transaction starts here ..."
	targetTx := targetSoil newTransaction.
	"... and somebody else commits before the import runs"
	meanwhile := targetSoil newTransaction.
	meanwhile root nested: 'moved on'.
	meanwhile markDirty: meanwhile root.
	meanwhile commit.
	self assert: targetTx readVersion < targetSoil control databaseVersion.

	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	self assert: importer importedObjects first notNil.
	self assert: importer importedObjects first nested equals: 'exported'.
	targetTx commit
]

{ #category : #tests }
SoilGraphExporterTest >> testExportCarriesTheEntriesOfAnIndex [
	"Without #skipIndexes: the entries of an index go along, and their values are object
	ids - a SoilSkipListDictionary holding objects is what a grid's rows are in
	ApptiveGrid. The exporter used to take those values for raw bytes and died on
	#readStream; #skipIndexes: hid it, because a skipped index writes its sizes and no
	entries at all."

	| tx bytes exportTx importer targetTx imported dictionary |
	tx := soil newTransaction.
	dictionary := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx root: dictionary.
	dictionary
		at: 1 put: (SoilTestGraphRoot new nested: 'first'; yourself);
		at: 2 put: (SoilTestGraphRoot new nested: 'second'; yourself).
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	targetSoil := Soil createOnPath: self targetPath.
	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.

	"read before the commit: what the dictionary answers is a proxy, and it would fault
	against a transaction that is gone by the time the assertion looks at it"
	self assert: (imported at: 1) nested equals: 'first'.
	self assert: (imported at: 2) nested equals: 'second'.
	targetTx commit
]

{ #category : #tests }
SoilGraphExporterTest >> testExportImportWithoutReorderRoundTrips [
	"sanity check: the common case (no reorder ever happened) must keep working"

	| tx object bytes exportTx importer imported targetTx |
	object := migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	targetSoil := Soil createOnPath: self targetPath.
	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	targetTx commit.

	self assert: (imported instVarNamed: #one) equals: 1.
	self assert: (imported instVarNamed: #two) equals: 2.
	self assert: (imported instVarNamed: #three) equals: 3
]

{ #category : #tests }
SoilGraphExporterTest >> testExportOfClusterNotTouchedSinceReorderMatchesLiveShape [
	"A cluster record can be written under an ivar order that later gets reordered in the
	class definition, without the record ever being re-serialized since (e.g. a dormant Form
	that predates a schema change). SoilGraphExporter>>updateCluster: is meant to migrate
	such a cluster to the current shape before writing it out, so that importing it into a
	database that has never seen the class before (and therefore has no shape to compare
	against) reconstructs the object correctly - see visitPersistentClusterVersion:."

	| tx object bytes exportTx importer imported targetTx |
	object := migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"reorder the class after the object was written - the stored cluster record now
	predates the current shape and was never touched again"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #three. #two };
		package: self class package name) install.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	targetSoil := Soil createOnPath: self targetPath.
	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	targetTx commit.

	self assert: (imported instVarNamed: #one) equals: 1.
	self assert: (imported instVarNamed: #two) equals: 2.
	self assert: (imported instVarNamed: #three) equals: 3
]

{ #category : #tests }
SoilGraphExporterTest >> testFailedImportDoesNotCorruptBehaviorRegistryForOtherClasses [
	"A partially-failing import (one class new to the target succeeds, a later class
	genuinely mismatches and raises) must not leave the succeeded class dangling in the
	behaviorRegistry name index - otherwise a later, unrelated write can reuse the same
	behavior index and alias two different classes onto it. See SoilGraphImporter>>import.

	The mismatch has to be a genuine one since the importer learned the version chain:
	a shape the target holds as an older version, or the one the live class has, are both
	ordinary and no longer raise. So the class changes a third time *after* the export -
	what arrives is then neither the target's shape nor this image's, which is what an
	exporting image running different code would send."

	| newClass mismatchClass thirdClass tx sourceExportTx exporter bytes importer targetTx |
	[
		newClass := (SoilBaseTestObject << #SOGraphImportNewClass
			layout: FixedLayout;
			slots: { #p1 };
			package: self class package name) install.

		mismatchClass := (SoilBaseTestObject << #SOGraphImportMismatchClass
			layout: FixedLayout;
			slots: { #q1 };
			package: self class package name) install.

		targetSoil := Soil createOnPath: self targetPath.
		tx := targetSoil newTransaction.
		tx root: (mismatchClass new instVarNamed: #q1 put: 'target-q1'; yourself).
		tx commit.

		"reorder only for the source - the target keeps its original, now-differing shape as current"
		mismatchClass := (SoilBaseTestObject << #SOGraphImportMismatchClass
			layout: FixedLayout;
			slots: { #q1. #q2 };
			package: self class package name) install.

		tx := soil newTransaction.
		tx root: (OrderedCollection new
			add: (newClass new instVarNamed: #p1 put: 'source-p1'; yourself);
			add: (mismatchClass new
				instVarNamed: #q1 put: 'source-q1';
				instVarNamed: #q2 put: 'source-q2';
				yourself);
			yourself).
		tx commit.

		sourceExportTx := soil newTransaction.
		bytes := ByteArray streamContents: [ :stream |
			(SoilGraphExporter new
				transaction: sourceExportTx;
				addObject: sourceExportTx root;
				yourself)
					stream: stream;
					export ].
		sourceExportTx abort.

		"the live shape moves on after the export: the bytes now carry a shape that is
		neither in the target's chain nor the class as it is here"
		mismatchClass := (SoilBaseTestObject << #SOGraphImportMismatchClass
			layout: FixedLayout;
			slots: { #q1. #q3 };
			package: self class package name) install.

		targetTx := targetSoil newTransaction.
		importer := SoilGraphImporter new
			transaction: targetTx;
			stream: bytes readStream;
			yourself.
		self should: [ importer import ] raise: SoilBehaviorShapeConflict.
		targetTx abort.

		self
			assert: (targetSoil behaviorRegistry nameAt: #SOGraphImportNewClass ifAbsent: [ #absent ])
			equals: #absent.

		"the database must still be usable for new data afterwards"
		thirdClass := (SoilBaseTestObject << #SOGraphImportThirdClass
			layout: FixedLayout;
			slots: { #r1 };
			package: self class package name) install.
		tx := targetSoil newTransaction.
		tx root: (thirdClass new instVarNamed: #r1 put: 'third-r1'; yourself).
		tx commit.

		tx := targetSoil newTransaction.
		self assert: (tx root instVarNamed: #r1) equals: 'third-r1'
	] ensure: [
		newClass ifNotNil: [ newClass removeFromSystem ].
		mismatchClass ifNotNil: [ mismatchClass removeFromSystem ].
		thirdClass ifNotNil: [ thirdClass removeFromSystem ] ]
]

{ #category : #tests }
SoilGraphExporterTest >> testImportOfAShapeTheTargetKnowsAsAnOlderVersion [
	"The stream carries a shape the target has already moved past: it holds a newer one as
	current and the imported one behind it in the chain. That is what arrives from an image
	running older code, and here it is produced by exporting first and changing the class
	afterwards - after which the exported shape is no longer the current one.

	The importer must point the objects at the version the chain already has, and they must
	read back through the usual shape adaptation."

	| tx bytes exportTx importer targetTx imported |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 'native-one';
		instVarNamed: #two put: 'native-two';
		instVarNamed: #three put: 'native-three';
		yourself).
	tx commit.

	tx := soil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself).
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	"the class moves on after the export"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #three. #two };
		package: self class package name) install.

	"and the target writes the new shape, so the exported one sits behind it in its chain"
	targetTx := targetSoil newTransaction.
	targetTx root: (migrationClass new
		instVarNamed: #one put: 'newer-one';
		instVarNamed: #two put: 'newer-two';
		instVarNamed: #three put: 'newer-three';
		yourself).
	targetTx commit.

	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		acceptExportsFromOlderVersions;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	targetTx commit.

	self assert: (imported instVarNamed: #one) equals: 1.
	self assert: (imported instVarNamed: #two) equals: 2.
	self assert: (imported instVarNamed: #three) equals: 3.

	"and it took the shape that was already in the chain rather than appending one:
	two versions written by the target, none added by the import"
	self
		assert: (targetSoil objectRepository metaSegment allVersionsAt:
				 (targetSoil behaviorRegistry
					  nameAt: #SOGraphExportMigrationObject
					  ifAbsent: [ self fail ]) index) size
		equals: 2
]

{ #category : #tests }
SoilGraphExporterTest >> testImportTakesTheNewestVersionOfAShapeThatOccursTwice [
	"A shape can appear more than once in a chain: take an instance variable away and put
	it back, and version 1 and version 3 look the same while meaning different things. The
	chain this builds is (3: one two three), (2: one two), (1: one two three) - measured,
	not assumed.

	The importer answers the newest of the two. What this test shows is that such a chain
	imports cleanly and keeps #three; it does *not* show that the older choice would lose
	it. It would not: PointerLayout>>updateIvars:with:for: does not migrate along the
	version the record carries, it looks the shape up again through
	#behaviorVersionsUpTo:transaction: - which takes the newest match as well. Tried with
	the lookup inverted to answer the oldest match, and this test stays green. The choice
	is still worth making deliberately: it is the one the materializer makes, and two
	answers to the same question are a place for the two to drift apart."

	| tx bytes exportTx importer targetTx imported |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 'v1-one';
		instVarNamed: #two put: 'v1-two';
		instVarNamed: #three put: 'v1-three';
		yourself).
	tx commit.

	tx := soil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself).
	tx commit.
	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	"version 2 in the target: #three is gone"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #two };
		package: self class package name) install.
	targetTx := targetSoil newTransaction.
	targetTx root: (migrationClass new
		instVarNamed: #one put: 'v2-one';
		instVarNamed: #two put: 'v2-two';
		yourself).
	targetTx commit.

	"version 3: #three is back, so this shape equals version 1"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #two. #three };
		package: self class package name) install.
	targetTx := targetSoil newTransaction.
	targetTx root: (migrationClass new
		instVarNamed: #one put: 'v3-one';
		instVarNamed: #two put: 'v3-two';
		instVarNamed: #three put: 'v3-three';
		yourself).
	targetTx commit.

	"version 4, so that the imported shape is not the current one"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #three. #two };
		package: self class package name) install.
	targetTx := targetSoil newTransaction.
	targetTx root: (migrationClass new
		instVarNamed: #one put: 'v4-one';
		instVarNamed: #two put: 'v4-two';
		instVarNamed: #three put: 'v4-three';
		yourself).
	targetTx commit.

	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		acceptExportsFromOlderVersions;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	targetTx commit.

	self assert: (imported instVarNamed: #one) equals: 1.
	self assert: (imported instVarNamed: #two) equals: 2.
	self assert: (imported instVarNamed: #three) equals: 3
]

{ #category : #tests }
SoilGraphExporterTest >> testImportOfALiveShapeBecomesTheNextVersionInTheTarget [
	"The target holds an older shape as its current one and the import brings the shape of
	the class as it lives in this image. That is not a conflict: it is what an ordinary
	commit in the target would have produced, and the importer appends it as the next
	version of the chain rather than reusing the description that is already there.

	Was testImportRaisesOnGenuineShapeMismatch, which expected an Error here. The
	protection that comment named - never silently reuse a description that does not fit -
	still holds, and is asserted below: the imported object reads back with its own values,
	which it could not if it had been read through the target's older description."

	| tx bytes exportTx importer targetTx imported |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 'native-one';
		instVarNamed: #two put: 'native-two';
		instVarNamed: #three put: 'native-three';
		yourself).
	tx commit.

	"reorder in the image - the target keeps its original shape as current"
	migrationClass := (SoilBaseTestObject << #SOGraphExportMigrationObject
		layout: FixedLayout;
		slots: { #one. #three. #two };
		package: self class package name) install.

	tx := soil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself).
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	imported := importer importedObjects first.
	targetTx commit.

	self assert: (imported instVarNamed: #one) equals: 1.
	self assert: (imported instVarNamed: #two) equals: 2.
	self assert: (imported instVarNamed: #three) equals: 3.

	"and the object that was already there is untouched"
	targetTx := targetSoil newTransaction.
	self assert: (targetTx root instVarNamed: #two) equals: 'native-two'.
	targetTx abort
]

{ #category : #tests }
SoilGraphExporterTest >> testImportedBehaviorSurvivesCloseAndReopenEvenWithoutOtherChanges [
	"SoilGraphImporter writes behavior descriptions and object data directly to the
	segments, bypassing the transaction's normal markDirty:/commitStrategy tracking.
	SoilTransactionManager>>commitTransaction: only checkpoints (which flushes the
	behaviorRegistry's skip list index to disk) when the transaction's own needsCommit
	is true. Committing right after an import with genuinely NOTHING else changed in the
	same transaction must not silently fail to persist the newly imported behavior - the
	space must still be usable after the target database is closed and reopened, not just
	within the same session."

	| tx object bytes exportTx importer targetTx path reopened importedOid |
	object := migrationClass new
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2;
		instVarNamed: #three put: 3;
		yourself.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	exportTx := soil newTransaction.
	bytes := ByteArray streamContents: [ :stream |
		(SoilGraphExporter new
			transaction: exportTx;
			addObject: exportTx root;
			yourself)
				stream: stream;
				export ].
	exportTx abort.

	path := self targetPath.
	targetSoil := Soil createOnPath: path.
	targetTx := targetSoil newTransaction.
	targetTx root: SoilPersistentDictionary new.
	targetTx commit.

	targetTx := targetSoil newTransaction.
	importer := SoilGraphImporter new
		transaction: targetTx;
		stream: bytes readStream;
		yourself.
	importer import.
	importedOid := targetTx objectIdOf: importer importedObjects first.
	"commit with genuinely nothing else touched - targetTx root is untouched, still the
	same empty dictionary committed above. This is the exact scenario that used to
	silently lose the import on the next close/reopen."
	targetTx commit.

	targetSoil close.
	reopened := Soil openOnPath: path.
	targetSoil := reopened.

	self
		assert: (reopened behaviorRegistry nameAt: #SOGraphExportMigrationObject ifAbsent: [ #absent ])
		~= #absent.

	tx := reopened newTransaction.
	self assert: ((tx objectWithId: importedOid) instVarNamed: #one) equals: 1.
	self assert: ((tx objectWithId: importedOid) instVarNamed: #two) equals: 2.
	self assert: ((tx objectWithId: importedOid) instVarNamed: #three) equals: 3
]
