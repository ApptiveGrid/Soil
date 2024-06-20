Class {
	#name : #SoilLockableStreamTest,
	#superclass : #TestCase,
	#instVars : [
		'stream'
	],
	#category : 'Soil-File-Tests'
}

{ #category : #running }
SoilLockableStreamTest >> setUp [ 
	super setUp.
	SoilFileLockRegistry reset 
]

{ #category : #running }
SoilLockableStreamTest >> tearDown [ 
	super tearDown.
	stream close.
	stream := nil
]

{ #category : #tests }
SoilLockableStreamTest >> testMemoryLock [
	| objA objB registry |
	objA := Object new.
	objB := Object new.
	stream := (SoilLockableStream path: '/tmp/soil-lock-test') lockOnlyInImage.
	stream nextPutAll: 'hello world'.
	stream lockFrom: 7 to: 12 for: objA.
	self assert: stream locks size equals: 1.
	registry := SoilFileLockRegistry forPath: '/tmp/soil-lock-test'.
	self assert: registry numberOfLocks equals: 1
]

{ #category : #tests }
SoilLockableStreamTest >> testMemoryLockConflict [
	| objA objB |
	objA := Object new.
	objB := Object new.
	stream := (SoilLockableStream path: '/tmp/soil-lock-test') lockOnlyInImage.
	stream 
		nextPutAll: 'hello world';
		flush.
	[ stream lockFrom: 7 to: 12 for: objA.
	self 
		should: [ stream lockFrom: 7 to: 12 for: objB ]
		raise: SoilAlreadyLocked ]
		ensure: [ stream releaseAllLocks ] .
]

{ #category : #tests }
SoilLockableStreamTest >> testMemoryUnlock [
	| objA objB |
	objA := Object new.
	objB := Object new.
	stream := (SoilLockableStream path: '/tmp/soil-lock-test') lockOnlyInImage.
	stream 
		nextPutAll: 'hello world';
		flush.
	stream lockFrom: 7 to: 12 for: objA.
	stream unlockFrom: 7 to: 12 for: objA.
	self assert: stream locks isEmpty .
]
