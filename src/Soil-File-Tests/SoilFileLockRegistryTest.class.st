Class {
	#name : #SoilFileLockRegistryTest,
	#superclass : #TestCase,
	#category : #'Soil-File-Tests'
}

{ #category : #initialization }
SoilFileLockRegistryTest >> setUp [
	super setUp.
	SoilFileLockRegistry reset
]

{ #category : #running }
SoilFileLockRegistryTest >> tearDown [ 
	super tearDown.
	SoilFileLockRegistry reset
]

{ #category : #tests }
SoilFileLockRegistryTest >> testAcquireAndGarbageCollect [
	| registry |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	self assert: registry numberOfLocks equals: 0.
	self assert: SoilFileLockRegistry numberOfRegistries > 0.
	registry := nil.
	[  SoilFileLockRegistry numberOfRegistries = 0 ] whileFalse: [ Smalltalk garbageCollect ].

	"The registry should have been vanished"
	self assert: SoilFileLockRegistry numberOfRegistries equals: 0.
]

{ #category : #tests }
SoilFileLockRegistryTest >> testAcquireRegistry [ 
	| registry |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	self assert: registry numberOfLocks equals: 0.
	self assert: SoilFileLockRegistry numberOfRegistries equals: 1
]

{ #category : #tests }
SoilFileLockRegistryTest >> testCanonicalizePaths [
	| registry registry2 |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry2 := SoilFileLockRegistry forPath: '/tmp/../tmp/foo'.
	self assert: registry == registry2
]

{ #category : #tests }
SoilFileLockRegistryTest >> testCanonicalizePathsTrailingSlash [
	| registry registry2 |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry2 := SoilFileLockRegistry forPath: '/tmp/foo/'.
	self assert: registry == registry2
]

{ #category : #tests }
SoilFileLockRegistryTest >> testLockBorderOverlapLowerBound [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 1 to: 100 for: pTwo ]
		raise: SoilAlreadyLocked 
]

{ #category : #tests }
SoilFileLockRegistryTest >> testLockBorderOverlapUpperBound [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 1000 to: 2000 for: pTwo ]
		raise: SoilAlreadyLocked 
]

{ #category : #tests }
SoilFileLockRegistryTest >> testLockSameRangeDifferentContext [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self
		should: [ registry lockFrom: 100 to: 1000 for: pTwo ]
		raise: SoilAlreadyLocked
]

{ #category : #tests }
SoilFileLockRegistryTest >> testLockSameRangeSameContext [
	| registry pOne |
	pOne := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 2.

]

{ #category : #tests }
SoilFileLockRegistryTest >> testLockSameRangeTwoProcesses [
	| registry pOneFailed pTwoFailed |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
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

{ #category : #tests }
SoilFileLockRegistryTest >> testTwoRegistries [
	| registry registry2 |
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry2 := SoilFileLockRegistry forPath: '/tmp/bar'.
	self deny: registry == registry2
]

{ #category : #tests }
SoilFileLockRegistryTest >> testUnlockDifferentContext [
	| registry pOne pTwo |
	pOne := Object new.
	pTwo := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self 
		should: [ registry unlockFrom: 100 to: 1001 for: pTwo ]
		raise: SoilLockNotFound.

]

{ #category : #tests }
SoilFileLockRegistryTest >> testUnlockInvalidRange [
	| registry pOne |
	pOne := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	self 
		should: [ registry unlockFrom: 100 to: 1001 for: pOne ]
		raise: SoilLockNotFound.

]

{ #category : #tests }
SoilFileLockRegistryTest >> testUnlockRangeSameContext [
	| registry pOne |
	pOne := Object new.
	registry := SoilFileLockRegistry forPath: '/tmp/foo'.
	registry lockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 1.
	"locking from the same context should always work"
	registry unlockFrom: 100 to: 1000 for: pOne.
	self assert: registry numberOfLocks equals: 0.

]
