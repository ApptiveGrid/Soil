Class {
	#name : #SoilLockingTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilLockingTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilLockingTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem 
]

{ #category : #running }
SoilLockingTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilLockingTest >> testObjectLocks [
	| tx obj |
	tx := soil newTransaction.
	obj := Object new.
	tx root: obj.
	tx commit.
]
