Class {
	#name : #SoilReadOnlyStrategyTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #tests }
SoilReadOnlyStrategyTest >> testDefaultsToErrorOnWriteAttempts [
	"SoilReadOnlyStrategy had no initialize - ignoreWriteAttempts defaulted to nil,
	which markDirty:/prepareCommit/recordMaterialized:materializer: all check via
	`ignoreWriteAttempts ifFalse: [...]`, crashing with a non-boolean-receiver error
	on any read-only transaction that never explicitly called errorOnWriteAttempts/
	ignoreWriteAttempts first (e.g. the plain Soil>>newReadOnlyTransaction path,
	as opposed to AGBaseDatabase's overridden one). Default should be the safe,
	protective behavior: error on write attempts."
	self should: [ SoilReadOnlyStrategy new markDirty: 42 ]
		raise: SoilWriteOnReadOnlyTransaction
]

{ #category : #tests }
SoilReadOnlyStrategyTest >> testIgnoreWriteAttemptsSuppressesTheError [
	| strategy |
	strategy := SoilReadOnlyStrategy new.
	strategy ignoreWriteAttempts.
	strategy markDirty: 42
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
