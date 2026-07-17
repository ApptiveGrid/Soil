Class {
	#name : #SoilFindRecordsVisitorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilFindRecordsVisitorTest >> path [
	^ 'soil-tests' asFileReference
]

{ #category : #initialization }
SoilFindRecordsVisitorTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilFindRecordsVisitorTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilFindRecordsVisitorTest >> testFindRecordsCollectsErrorInsteadOfAbortingOnCorruptedObject [
	"A materialize error for one object during find:in: must not abort the whole
	scan - the error should be collected and the scan should continue over the
	remaining reachable objects instead of raising out of find:in:."
	| tx objectsFile bytes visitor |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #hello)).
	tx makeRoot: tx root nested.
	tx commit.
	soil close.

	objectsFile := self path / 'segments' / '1' / 'objects'.
	bytes := objectsFile binaryReadStream next: 30.
	objectsFile delete.
	objectsFile binaryWriteStream nextPutAll: bytes; close.

	soil := Soil path: self path.
	soil open.
	tx := soil newTransaction.
	visitor := SoilFindRecordsVisitor new.
	visitor find: [ :r | true ] in: tx.
	self assert: visitor errors isNotEmpty.
	self assert: visitor records isNotEmpty
]
