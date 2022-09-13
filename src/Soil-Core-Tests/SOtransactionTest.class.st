Class {
	#name : #SOtransactionTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOtransactionTest >> testEmptyAbort [
	| tx |
	tx := SOTransaction new.
	tx root: Object new.
	tx abort.
	self assert: tx isAborted
]
