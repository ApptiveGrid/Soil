Class {
	#name : #SoilLockableStreamTest,
	#superclass : #TestCase,
	#instVars : [
		'stream'
	],
	#category : #'Soil-File-Tests'
}

{ #category : #running }
SoilLockableStreamTest >> path [
	"not '/tmp/...': there is no /tmp on Windows, the open then fails and the test
	dies in tearDown on a stream that was never created"

	^ FileLocator temp / 'soil-lock-test'
]

{ #category : #initialization }
SoilLockableStreamTest >> setUp [ 
	super setUp.
	self path ensureDelete.
	SoilFileLockRegistry reset 
]

{ #category : #running }
SoilLockableStreamTest >> tearDown [ 
	super tearDown.
	"guarded: if the test never got as far as opening the stream, tearDown must not
	bury the real failure under a doesNotUnderstand"
	stream ifNotNil: [ stream close ].
	stream := nil.
	self path ensureDelete
]

{ #category : #tests }
SoilLockableStreamTest >> testMemoryLock [
	| objA objB registry |
	objA := Object new.
	objB := Object new.
	stream := (SoilLockableStream path: self path) lockOnlyInImage.
	stream nextPutAll: 'hello world'.
	stream lockFrom: 7 to: 12 for: objA.
	self assert: stream locks size equals: 1.
	registry := SoilFileLockRegistry forPath: self path.
	self assert: registry numberOfLocks equals: 1
]

{ #category : #tests }
SoilLockableStreamTest >> testMemoryLockConflict [
	| objA objB |
	objA := Object new.
	objB := Object new.
	stream := (SoilLockableStream path: self path) lockOnlyInImage.
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
	stream := (SoilLockableStream path: self path) lockOnlyInImage.
	stream 
		nextPutAll: 'hello world';
		flush.
	stream lockFrom: 7 to: 12 for: objA.
	stream unlockFrom: 7 to: 12 for: objA.
	self assert: stream locks isEmpty .
]
