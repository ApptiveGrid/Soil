Class {
	#name : #SoilTransactionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilTransactionTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilTransactionTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem 
]

{ #category : #running }
SoilTransactionTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilTransactionTest >> testCheckpointAndContinue [
	| tx |
	tx := soil newTransaction.
	tx root: Object new.
	tx checkpointAndContinue.
	self deny: tx hasModifications.
	 
	
]

{ #category : #tests }
SoilTransactionTest >> testRootObjectModifies [ 
	| tx obj |
	obj := Object new.
	tx := soil newTransaction.
	tx root: obj.
	self assert: tx hasModifications.
	self assert: tx isChanged.
	self assert: (tx isRoot: obj).
	self assert: (tx isPersistent: obj)
	 

]
