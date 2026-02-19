Class {
	#name : 'SoilWindowsFileLockTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'stream'
	],
	#category : 'Soil-File-Tests',
	#package : 'Soil-File-Tests'
}

{ #category : 'running' }
SoilWindowsFileLockTest >> setUp [
	super setUp.
	testFile := 'soil-winlock-test.tmp' asFileReference.
	testFile ensureDelete
]

{ #category : 'running' }
SoilWindowsFileLockTest >> tearDown [
	stream ifNotNil: [
		[ stream close ] on: Error do: [ :ex | "ignore close errors" ] ].
	testFile ifNotNil: [
		[ testFile ensureDelete ] on: Error do: [ :ex | "ignore delete errors" ] ].
	super tearDown
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testErrorDescriptions [
	"Test error description helper method"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	"Test known error codes"
	self assert: (SoilWindowsFileLock errorDescription: 5) equals: 'Access denied'.
	self assert: (SoilWindowsFileLock errorDescription: 6) equals: 'Invalid file handle'.
	self assert: (SoilWindowsFileLock errorDescription: 33) equals: 'Lock violation (region already locked)'.
	self assert: (SoilWindowsFileLock errorDescription: 158) equals: 'Region not locked'.

	"Test unknown error code"
	self assert: ((SoilWindowsFileLock errorDescription: 9999) includesSubstring: 'Unknown error')
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testFlushFileBuffersDirect [
	"Test FlushFileBuffers FFI call directly"

	| result |
	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Testing direct FlushFileBuffers call'.
	stream flush.

	"Call FlushFileBuffers directly"
	result := SoilWindowsFileLock flushFileBuffers: stream fileStream fileHandle.

	"Should return true (non-zero) on success"
	self assert: result
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testFsyncEntireFile [
	"Test fsync on Windows using FlushFileBuffers"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Testing fsync on Windows!'.
	stream flush.

	"Call fsync - should not raise an error"
	self shouldnt: [ stream fileStream fsync ] raise: Error.

	stream close
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testLockAndUnlockEntireFile [
	"Test locking and unlocking the entire file (length = 0)"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Hello, Windows file locking!'.
	stream flush.

	"Lock entire file"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 0 length: 0).

	"Unlock entire file"
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 0)
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testLockAndUnlockRange [
	"Test locking and unlocking a specific byte range"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Hello, Windows file locking!'.
	stream flush.

	"Lock bytes 7 to 14 (the word 'Windows')"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 7 length: 7).

	"Unlock the same range"
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 7 length: 7)
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testLockExclusive [
	"Test exclusive lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test exclusive lock'.
	stream flush.

	"Lock with exclusive flag"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 0 length: 100 exclusive: true).

	"Unlock"
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100)
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testLockOrErrorSuccess [
	"Test lockOrError with successful lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test lockOrError success'.
	stream flush.

	"Should not raise an error"
	self shouldnt: [
		SoilWindowsFileLock lockOrError: stream fileStream fileHandle from: 0 length: 100 exclusive: true ]
		raise: Error.

	"Clean up"
	SoilWindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testLockShared [
	"Test shared lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test shared lock'.
	stream flush.

	"Lock with shared flag"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 0 length: 100 exclusive: false).

	"Unlock"
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100)
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testMultipleLocks [
	"Test locking multiple non-overlapping ranges"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: '0123456789ABCDEFGHIJ'.
	stream flush.

	"Lock range 0-9"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 0 length: 10).

	"Lock range 10-19 (non-overlapping)"
	self assert: (SoilWindowsFileLock lock: stream fileStream fileHandle from: 10 length: 10).

	"Unlock both ranges"
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 10).
	self assert: (SoilWindowsFileLock unlock: stream fileStream fileHandle from: 10 length: 10)
]

{ #category : 'tests' }
SoilWindowsFileLockTest >> testWinOverlappedStructure [
	"Test WinOverlapped structure initialization and field access"

	| overlapped |
	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	overlapped := SoilWinOverlappedStruct new.

	"Test field setters and getters"
	overlapped offset: 16r12345678.
	self assert: overlapped offset equals: 16r12345678.

	overlapped offsetHigh: 16rABCDEF00.
	self assert: overlapped offsetHigh equals: 16rABCDEF00.

	overlapped internal: 0.
	self assert: overlapped internal equals: 0.

	overlapped internalHigh: 0.
	self assert: overlapped internalHigh equals: 0.

	overlapped hEvent: ExternalAddress null.
	self assert: overlapped hEvent getHandle equals: ExternalAddress null
]
