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
SOLockingTest >> testObjectLocks [
	| tx obj |
	tx := soil newTransaction.
	obj := Object new.
	tx root: obj.
	tx commit
]
