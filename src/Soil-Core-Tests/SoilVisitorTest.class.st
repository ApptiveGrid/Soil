Class {
	#name : #SoilVisitorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilVisitorTest >> path [
	^ 'soil-tests' asFileReference
]

{ #category : #initialization }
SoilVisitorTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem
]

{ #category : #helpers }
SoilVisitorTest >> simpleGraph [
	^ SoilTestGraphRoot new
		nested: (SoilTestNestedObject new
			label: 'nested under root';
			reference: (SoilTestClusterRoot new
				nested: (SoilTestNestedObject new label: 'nested under cluster'));
			yourself);
		yourself
]

{ #category : #running }
SoilVisitorTest >> tearDown [
	super tearDown.
	soil ifNotNil: [
		soil close ]
]

{ #category : #tests }
SoilVisitorTest >> testAVisitorHandedATransactionReadsAtItsVersion [
	"A visitor read at the database version it found on its first read, whatever
	transaction it had been handed. A commit between opening that transaction and the
	visit gave it records the transaction does not see"
	| tx reader writer root |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: 'before'; yourself).
	tx commit.
	reader := soil newTransaction.
	writer := soil newTransaction.
	writer root nested: 'after'.
	writer commit.

	root := (reader findRecords: [ :each | each objectId = SoilObjectId root ]) first.
	self assert: root version equals: reader readVersion.
	root materializeObject.
	self assert: root object nested equals: 'before'.
	reader abort
]

{ #category : #tests }
SoilVisitorTest >> testAVisitorReadsAnIndexAtItsVersion [
	"An index was read as it is now. An entry committed after the version the records
	are read at points to an object that has no version there, and reading it ended in
	'nil objectId:'"
	| tx dict reader writer before visitor |
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 3 do: [ :n | dict at: n put: (SoilTestNestedObject new label: n printString) ].
	tx commit.
	reader := soil newTransaction.
	before := (reader findRecords: [ :each | true ]) size.
	writer := soil newTransaction.
	writer root at: 4 put: (SoilTestNestedObject new label: 'late').
	writer commit.

	visitor := SoilFindRecordsVisitor new.
	visitor find: [ :each | true ] in: reader.
	self assert: visitor errors isEmpty.
	self assert: visitor records size equals: before.
	reader abort
]

{ #category : #tests }
SoilVisitorTest >> testAVisitorWalkingDepthFirstReadsAtItsVersion [
	"The depth-first walk read the current version of each record, whatever version the
	visitor was at"
	| tx reader writer visitor root |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: 'before'; yourself).
	tx commit.
	reader := soil newTransaction.
	writer := soil newTransaction.
	writer root nested: 'after'.
	writer commit.

	visitor := SoilFindRecordsVisitor new.
	visitor beDepthFirst.
	visitor find: [ :each | each objectId = SoilObjectId root ] in: reader.
	root := visitor records first.
	self assert: root version equals: reader readVersion.
	reader abort
]

{ #category : #tests }
SoilVisitorTest >> testBreadthFirstIsDefault [
	self deny: (SoilVisitor new instVarNamed: #depthFirst)
]

{ #category : #tests }
SoilVisitorTest >> testDepthFirstTraversalDoesNotRaiseError [
	"SoilVisitor>>beDepthFirst used to set seen to nil, while processObjectId:/processReference:
	unconditionally send #includes: to seen regardless of the depthFirst/breadthFirst mode.
	This made depth-first traversal raise a doesNotUnderstand as soon as any object
	reference was visited. seen must track visited objects in both modes; only the
	toBeProcessed queue is breadth-first-only. Uses a graph with two clusters (an
	external reference) to force at least one #processReference: call."
	| tx graph visitor |
	tx := soil newTransaction.
	graph := self simpleGraph.
	tx makeRoot: graph nested reference.
	tx root: graph.
	tx basicCommit.

	visitor := SoilVisitor new.
	visitor soil: soil.
	visitor beDepthFirst.

	self shouldnt: [ visitor visit: soil ] raise: Error
]
