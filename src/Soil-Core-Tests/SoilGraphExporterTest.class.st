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
	behavior index and alias two different classes onto it. See SoilGraphImporter>>import."

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

		targetTx := targetSoil newTransaction.
		importer := SoilGraphImporter new
			transaction: targetTx;
			stream: bytes readStream;
			yourself.
		self should: [ importer import ] raise: Error.
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
SoilGraphExporterTest >> testImportRaisesOnGenuineShapeMismatch [
	"if the target database already has a native, current behavior description for the
	class that genuinely differs from what is being imported, the importer must fail loudly
	instead of silently reusing the wrong description - see SoilGraphImporter>>importBehaviorCluster:."

	| tx object bytes exportTx importer targetTx |
	targetSoil := Soil createOnPath: self targetPath.
	tx := targetSoil newTransaction.
	tx root: (migrationClass new
		instVarNamed: #one put: 'native-one';
		instVarNamed: #two put: 'native-two';
		instVarNamed: #three put: 'native-three';
		yourself).
	tx commit.

	"reorder only in the source's understanding - the target keeps its original shape as current"
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
	self should: [ importer import ] raise: Error.
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
