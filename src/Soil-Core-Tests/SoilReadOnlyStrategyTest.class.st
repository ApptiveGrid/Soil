Class {
	#name : #SoilReadOnlyStrategyTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #tests }
SoilReadOnlyStrategyTest >> testDefaultsToIgnoreWriteAttempts [
	
	self shouldnt: [ SoilReadOnlyStrategy new markDirty: 42 ]
		raise: SoilWriteOnReadOnlyTransaction
]

{ #category : #tests }
SoilReadOnlyStrategyTest >> testErrorOnWriteAttemptsAfterIgnore [
	| strategy |
	strategy := SoilReadOnlyStrategy new.
	strategy ignoreWriteAttempts.
	strategy errorOnWriteAttempts.
	self should: [ strategy markDirty: 42 ]
		raise: SoilWriteOnReadOnlyTransaction
]

{ #category : #tests }
SoilReadOnlyStrategyTest >> testIgnoreWriteAttemptsSuppressesTheError [
	| strategy |
	strategy := SoilReadOnlyStrategy new.
	strategy ignoreWriteAttempts.
	strategy markDirty: 42
]
