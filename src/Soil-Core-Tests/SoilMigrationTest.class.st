Class {
	#name : #SoilMigrationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'as yet unclassified' }
SoilMigrationTest >> createMigrationClass [
	^ (SOBaseTestObject << #SOMigrationObject 
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #accessing }
SoilMigrationTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilMigrationTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem.
	migrationClass := self createMigrationClass
]

{ #category : #running }
SoilMigrationTest >> tearDown [ 
	super tearDown.
	migrationClass removeFromSystem 
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
	self assert: materializedRoot nested reference class equals: SOProxy.
	self assert: materializedRoot nested reference nested label equals: 'nested under cluster'
	
]
