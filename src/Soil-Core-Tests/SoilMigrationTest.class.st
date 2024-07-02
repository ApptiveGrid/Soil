Class {
	#name : #SoilMigrationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassByteLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
		layout: ByteLayout;
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassFixedLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassFixedLayout2 [
	^ (SoilBaseTestObject << #SOMigrationObject2
		layout: FixedLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassVariableLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
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
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectByteLayputFromFixedLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a variable class with the same ivars"
	migrationClass := self createMigrationClassByteLayout.
	tx2 := soil newTransaction.

	self should: [materializedRoot := tx2 root] raise: SoilLayoutMigrationError

]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectFixedLayputFromByteLayout [
	| tx tx2 materializedRoot object |

	"We can load Variable Byte object as a Fixed object, we raise an error"

	object := self createMigrationClassByteLayout new: 10.
	self assert: object class isVariable.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a fixed class with the same ivars"
	migrationClass := self createMigrationClassFixedLayout.
	tx2 := soil newTransaction.

	self should: [materializedRoot := tx2 root] raise: SoilLayoutMigrationError
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectFixedLayputFromVariableLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassVariableLayout new.
	self assert: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a fixed class with the same ivars"
	migrationClass := self createMigrationClassFixedLayout.
	tx2 := soil newTransaction.

	materializedRoot := tx2 root.
	self deny: materializedRoot class isVariable.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectRenamedClass [
		| tx tx2 materializedRoot object |

	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	tx := soil newTransaction.
	tx root: object.
	tx commit.
	"now we remove the class and create a new one with a different name"
	migrationClass removeFromSystem.
	migrationClass := self createMigrationClassFixedLayout2.

	"We have to tell soil that the class was renamed"
	soil renameClassNamed: #SOMigrationObject to: #SOMigrationObject2.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class name equals: 'SOMigrationObject2'
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectRenamedClassPharo12 [
	| tx tx2 materializedRoot object |
	
	"alternative way to support class renames using a Pharo12 feature"
	
	SystemVersion current major <12 ifTrue: [ self skip].
	
	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	tx := soil newTransaction.
	tx root: object.
	tx commit.
	"now we remove the class and create a new one with a different name"
	migrationClass removeFromSystem.
	migrationClass := self createMigrationClassFixedLayout2.
	"use the Pharo12 aliasing, this would be normally done in a class side initialize method"
	migrationClass deprecatedAliases: #(#SOMigrationObject).

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class name equals: 'SOMigrationObject2'
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectVariableLayputFromFixedLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a variable class with the same ivars"
	migrationClass := self createMigrationClassVariableLayout.
	tx2 := soil newTransaction.

	materializedRoot := tx2 root.
	self assert: materializedRoot class isVariable.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
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
SoilMigrationTest >> testMaterializingObjectWithIVarRemovedAndAddedBack [

	| tx tx2 root materializedRoot object |

	"this test checks that removing an ivar and adding it back later means this is a new ivar,
	this makes sure iterating over behavior description history works, see
	 PointerLayout>>#updateIvars:with:for:"
	root := Dictionary new.
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	root at: #version1 put: object.
	tx root: root.
	tx commit.

	"now we change the class and store an object with the changed shape"

	migrationClass
		removeSlot: (migrationClass slotNamed: #two).

	object := migrationClass new.
	object
		instVarNamed: #one put: 'one'.
	root
		at: #version2 put: object.

	tx := soil newTransaction.
	tx root: root.
	tx commit.

	migrationClass := (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #one .#two . #three };
		package: self class package name) install.

	"load back, the object at #varsion1 loads the stored two ivars"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: ((materializedRoot at: #version1) instVarNamed: #one ) equals: 1.
	self assert: ((materializedRoot at: #version2) instVarNamed: #one ) equals: 'one'.
	"the ivar for both is nil"
	self assert: ((materializedRoot at: #version1) instVarNamed: #two ) equals: nil.
	self assert: ((materializedRoot at: #version2) instVarNamed: #two ) equals: nil
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
	
	"load it"	
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.

	"lets try to commit with the class changed"
	tx := soil newTransaction.
	tx root: materializedRoot.
	tx commit.

	"load again"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithMultipleChangesinHistory [
	| tx tx2 root materializedRoot object |

	"this test checks that we can read object where we change multiple times the class"
	root := Dictionary new.
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	root at: #version1 put: object.
	tx root: root.
	tx commit.

	"now we change the class and store an object with the changed shape"

	migrationClass
		removeSlot: (migrationClass slotNamed: #two).

	object := migrationClass new.
	object
		instVarNamed: #one put: 'one'.
	root
		at: #version2 put: object.

	tx := soil newTransaction.
	tx root: root.
	tx commit.

	"load back, the object at #varsion1 loads the stored two ivars"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: ((materializedRoot at: #version1) instVarNamed: #one ) equals: 1.
	self assert: ((materializedRoot at: #version2) instVarNamed: #one ) equals: 'one'
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
	
	migrationClass := (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #two .#one }; 
		package: self class package name) install.
	
	
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingVersionUpdateBug [
	| tx tx2 object dict object2 tx3 |
	
	"create a class with two instVars one and two"
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	dict := SoilPersistentDictionary new.
	"put the version 1 shaped object under key v1"
	dict at: #v1 put: object.
	tx := soil newTransaction.
	tx root: dict. 
	"commit the object will write the first version of the behavior description"
	tx commit.

	"now we change the shape of the class"
	migrationClass 
		addSlot: #three asSlot.
	object2 := migrationClass new.
	object2 instVarNamed: #three put: 3.
	tx2 := soil newTransaction.
	"putting the version 2 shape of the object under key v2 to distinguish from v1"
	tx2 root at: #v2 put: object2.
	tx2 markDirty: object2.
	"committing will write version 2 of the behavior description"
	tx2 commit.
	
	"change the class again so it is distinction to the version 2 shape"
	migrationClass 
		 addSlot: #four asSlot.
	tx3 := soil newTransaction.
	"materializing the version 1 object caused a mismatch in version tracking. We ended up with 
	two behavior description that have version 2"
	(tx3 root at: #v1) yourself.
	"reading the version 2 object will try to load version 2 of the behavior description but will
	fail materializing because it gets the third version 2 (which should have been version 3) that
	has more instVars as version 2 and it will fail reading as the stream is running short"
	self 
		shouldnt: [ (tx3 root at: #v2) yourself ]
		raise: Error.
	tx3 abort.

]

{ #category : #tests }
SoilMigrationTest >> testSerializingObjectWithChangedShape [
	| tx tx2 materializedRoot object tx3 description topDescription obj |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	tx2 := soil newTransaction.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.
	tx2 markDirty: tx2 root.
	tx2 commit.
	
	tx3 := soil newTransaction.
	materializedRoot := tx3 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.
	description := tx3 behaviorDescriptionFor: materializedRoot class.
	self assert: description version equals: 2.
	topDescription := soil behaviorRegistry nameAt: materializedRoot class soilBehaviorIdentifier ifAbsent: [ self fail ].
	self assert: (soil objectRepository allVersionsOf: topDescription) size equals: 2
]
