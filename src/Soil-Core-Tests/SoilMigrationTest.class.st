Class {
	#name : #SoilMigrationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassFixedLayout [
	^ (SOBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassVariableLayout [
	^ (SOBaseTestObject << #SOMigrationObject
		layout: VariableLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #accessing }
SoilMigrationTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilMigrationTest >> runCase [ 
	SystemAnnouncer uniqueInstance 
		suspendAllWhile: [ super runCase ]
]

{ #category : #running }
SoilMigrationTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem.
	migrationClass := self createMigrationClassFixedLayout
]

{ #category : #running }
SoilMigrationTest >> tearDown [ 
	migrationClass removeFromSystem.
	super tearDown
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectVariableLayputWithChangedShape [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassVariableLayout new.
	self assert: object class isVariable.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithChangedShape [
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemoved [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two).

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemoved2 [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #one).

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2.
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemovedThenCommit [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.
	migrationClass
		removeSlot: (migrationClass slotNamed: #two).

	"lets try to commit with the class changed"
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithReOrderedIvars [
	| tx tx2 materializedRoot object |
	
	"this test checks that we can read objects where the order of the ivars changed. This happens for 
	example when moving ivars up or down in the hierarchy"
	
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	
	migrationClass := (SOBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #two .#one }; 
		package: self class package name) install.
	
	
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]
