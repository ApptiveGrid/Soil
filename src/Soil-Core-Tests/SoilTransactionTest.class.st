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

{ #category : #tests }
SoilTransactionTest >> testRootObjectModifies [ 
	| tx |
	tx := soil newTransaction.
	tx root: Object new.
	self assert: tx hasModifications.
	self assert: tx isChanged.
	 
	
]
