Class {
	#name : #SOFileLockRegistryTest,
	#superclass : #TestCase,
	#category : #'Soil-File-Tests'
}

{ #category : #running }
SOFileLockRegistryTest >> tearDown [ 
	super tearDown.
	SOFileLockRegistry reset
]

{ #category : #tests }
SOFileLockRegistryTest >> testAcquireAndGarbageCollect [
	| registry |
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	self assert: registry numberOfLocks equals: 0.
	self assert: SOFileLockRegistry numberOfRegistries equals: 1.
	registry := nil.
	3 timesRepeat: [ Smalltalk garbageCollect ].
	"The registry should have been vanished"
	self assert: SOFileLockRegistry numberOfRegistries equals: 0.
]

{ #category : #tests }
SOFileLockRegistryTest >> testAcquireRegistry [ 
	| registry |
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	self assert: registry numberOfLocks equals: 0.
	self assert: SOFileLockRegistry numberOfRegistries equals: 1
]

{ #category : #tests }
SOFileLockRegistryTest >> testLockBorderOverlapLowerBound [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 1 to: 100 for: pTwo ]
		raise: SOAlreadyLocked 
]

{ #category : #tests }
SOFileLockRegistryTest >> testLockBorderOverlapUpperBound [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 1000 to: 2000 for: pTwo ]
		raise: SOAlreadyLocked 
]

{ #category : #tests }
SOFileLockRegistryTest >> testLockSameRangeDifferentContext [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 100 to: 1000 for: pTwo ]
		raise: SOAlreadyLocked
]

{ #category : #tests }
SOFileLockRegistryTest >> testLockSameRangeSameContext [
	| registry pOne |
	pOne := Object new.
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 2.

]

{ #category : #tests }
SOFileLockRegistryTest >> testLockSameRangeTwoProcesses [
	| registry pOneFailed pTwoFailed |
	registry := SOFileLockRegistry forPath: '/tmp/foo'.
	pOneFailed := false.
	pTwoFailed := false.
	[ 
		[ registry lockFrom: 100 to: 1000 for: Processor activeProcess ] 
			on: Error do: [ :err| Transcript show: err messageText; cr. pOneFailed := true ] ] fork.
	[ 
		50 milliSeconds wait.
	   [ registry lockFrom: 100 to: 1000 for: Processor activeProcess ] 
			on: Error do: [ :err| pTwoFailed := true ]  ] fork.
	100 milliSeconds wait.
	self assert: registry numberOfLocks equals: 1.
	self deny: pOneFailed.
	self assert: pTwoFailed.
	
]
