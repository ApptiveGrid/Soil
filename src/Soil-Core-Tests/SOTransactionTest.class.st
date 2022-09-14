Class {
	#name : #SOTransactionTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOTransactionTest >> testAddSameIdTwice [
	| tx |
	tx := SOTransaction new.
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	self assert: tx dirtyObjects size equals: 2
]

{ #category : #tests }
SOTransactionTest >> testEmptyAbort [
	| tx |
	tx := SOTransaction new.
	tx root: Object new.
	tx abort.
	self assert: tx isAborted
]
