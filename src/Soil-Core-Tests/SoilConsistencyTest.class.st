Class {
	#name : #SoilConsistencyTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilConsistencyTest >> commitSampleGraph [
	| tx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx := soil newTransaction.
	tx root nested label: #v2.
	tx markDirty: tx root nested.
	tx commit
]

{ #category : #running }
SoilConsistencyTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-consistency-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilConsistencyTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilConsistencyTest >> testCheckConsistencyPassesAfterGarbageCollect [
	"the GC must leave the database I3/I6-consistent."
	self commitSampleGraph.
	soil garbageCollect.
	self shouldnt: [ soil checkConsistency ] raise: Error
]

{ #category : #tests }
SoilConsistencyTest >> testCheckConsistencyPassesOnHealthyDatabase [
	self commitSampleGraph.
	self shouldnt: [ soil checkConsistency ] raise: Error
]

{ #category : #tests }
SoilConsistencyTest >> testCheckConsistencyRaisesOnVersionMismatch [
	"I6: a divergence between scanned max version and control databaseVersion is caught."
	self commitSampleGraph.
	soil control databaseVersion: 999.
	self should: [ soil checkConsistency ] raise: Error
]

{ #category : #tests }
SoilConsistencyTest >> testConsistencyVisitorValidateRaisesOnInconsistency [
	"I3: validate: raises when the check finds any error."
	self commitSampleGraph.
	self should: [ SoilConsistencyFailingVisitor new validate: soil ] raise: Error
]
