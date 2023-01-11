Class {
	#name : #SOLockableStreamTest,
	#superclass : #TestCase,
	#instVars : [
		'stream'
	],
	#category : #'Soil-File-Tests'
}

{ #category : #running }
SOLockableStreamTest >> tearDown [ 
	super tearDown.
	stream releaseAllLocks
]

{ #category : #tests }
SOLockableStreamTest >> testMemoryLock [
	| objA objB registry |
	objA := Object new.
	objB := Object new.
	stream := SOLockableStream path: '/tmp/soil-lock-test'.
	stream nextPutAll: 'hello world'.
	stream memoryLockFrom: 7 to: 12 for: objA.
	self assert: stream locks size equals: 1.
	registry := SOFileLockRegistry forPath: '/tmp/soil-lock-test'.
	self assert: registry numberOfLocks equals: 1
]

{ #category : #tests }
SOLockableStreamTest >> testMemoryLockConflict [
	| objA objB |
	objA := Object new.
	objB := Object new.
	stream := SOLockableStream path: '/tmp/soil-lock-test'.
	stream 
		nextPutAll: 'hello world';
		flush.
	[ stream memoryLockFrom: 7 to: 12 for: objA.
	self 
		should: [ stream memoryLockFrom: 7 to: 12 for: objB ]
		raise: SOAlreadyLocked ]
		ensure: [ stream releaseAllLocks ] .
]

{ #category : #tests }
SOLockableStreamTest >> testMemoryUnlock [
	| objA objB |
	objA := Object new.
	objB := Object new.
	stream := SOLockableStream path: '/tmp/soil-lock-test'.
	stream 
		nextPutAll: 'hello world';
		flush.
	[ 
		stream memoryLockFrom: 7 to: 12 for: objA.
		stream memoryUnlockFrom: 7 to: 12 for: objA.
		self assert: stream locks isEmpty ]
		ensure: [ stream releaseAllLocks ] .
]
