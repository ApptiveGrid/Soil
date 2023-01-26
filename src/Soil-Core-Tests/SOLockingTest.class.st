Class {
	#name : #SOLockingTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOLockingTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SOLockingTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem 
]

{ #category : #tests }
SOLockingTest >> testChangedReadVersion [
	| obj tx1 tx2 tx3 |
	obj := SOTestGraphRoot new 
		nested: (SOTestNestedObject new label: 'first').
	tx1 := soil newTransaction.
	tx1 root: obj.
	tx1 commit.
	tx2 := soil newTransaction.
	tx2 root nested label: 'second'.
	tx2 markDirty: tx2 root.
	tx3 := soil newTransaction.
	tx3 root nested label: 'third'.
	tx3 markDirty: tx3 root.
	tx3 commit.
	self 
		should: [ tx2 commit ]
		raise: SOObjectHasConcurrentChange 
]

{ #category : #tests }
SOLockingTest >> testObjectLocks [
	| tx obj |
	tx := soil newTransaction.
	obj := Object new.
	tx root: obj.
	tx commit.
]
