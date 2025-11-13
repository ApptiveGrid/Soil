Class {
	#name : 'WindowsFileLockTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'stream'
	],
	#category : 'Soil-File-Tests',
	#package : 'Soil-File-Tests'
}

{ #category : 'running' }
WindowsFileLockTest >> setUp [
	super setUp.
	testFile := 'soil-winlock-test.tmp' asFileReference.
	testFile ensureDelete
]

{ #category : 'running' }
WindowsFileLockTest >> tearDown [
	stream ifNotNil: [
		[ stream close ] on: Error do: [ :ex | "ignore close errors" ] ].
	testFile ifNotNil: [
		[ testFile ensureDelete ] on: Error do: [ :ex | "ignore delete errors" ] ].
	super tearDown
]

{ #category : 'tests' }
WindowsFileLockTest >> testErrorDescriptions [
	"Test error description helper method"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	"Test known error codes"
	self assert: (WindowsFileLock errorDescription: 5) equals: 'Access denied'.
	self assert: (WindowsFileLock errorDescription: 6) equals: 'Invalid file handle'.
	self assert: (WindowsFileLock errorDescription: 33) equals: 'Lock violation (region already locked)'.
	self assert: (WindowsFileLock errorDescription: 158) equals: 'Region not locked'.

	"Test unknown error code"
	self assert: ((WindowsFileLock errorDescription: 9999) includesSubstring: 'Unknown error')
]

{ #category : 'tests' }
WindowsFileLockTest >> testFdatasyncEntireFile [
	"Test fdatasync on Windows (should call same as fsync)"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Testing fdatasync on Windows!'.
	stream flush.

	"Call fdatasync - should not raise an error"
	self shouldnt: [ stream fileStream fdatasync ] raise: Error.

	stream close
]

{ #category : 'tests' }
WindowsFileLockTest >> testFlushFileBuffersDirect [
	"Test FlushFileBuffers FFI call directly"

	| result |
	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Testing direct FlushFileBuffers call'.
	stream flush.

	"Call FlushFileBuffers directly"
	result := WindowsFileLock flushFileBuffers: stream fileStream fileHandle.

	"Should return true (non-zero) on success"
	self assert: result
]

{ #category : 'tests' }
WindowsFileLockTest >> testFsyncEntireFile [
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
WindowsFileLockTest >> testLockAndUnlockEntireFile [
	"Test locking and unlocking the entire file (length = 0)"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Hello, Windows file locking!'.
	stream flush.

	"Lock entire file"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 0 length: 0).

	"Unlock entire file"
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 0)
]

{ #category : 'tests' }
WindowsFileLockTest >> testLockAndUnlockRange [
	"Test locking and unlocking a specific byte range"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Hello, Windows file locking!'.
	stream flush.

	"Lock bytes 7 to 14 (the word 'Windows')"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 7 length: 7).

	"Unlock the same range"
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 7 length: 7)
]

{ #category : 'tests' }
WindowsFileLockTest >> testLockExclusive [
	"Test exclusive lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test exclusive lock'.
	stream flush.

	"Lock with exclusive flag"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 0 length: 100 exclusive: true).

	"Unlock"
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100)
]

{ #category : 'tests' }
WindowsFileLockTest >> testLockOrErrorSuccess [
	"Test lockOrError with successful lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test lockOrError success'.
	stream flush.

	"Should not raise an error"
	self shouldnt: [
		WindowsFileLock lockOrError: stream fileStream fileHandle from: 0 length: 100 exclusive: true ]
		raise: Error.

	"Clean up"
	WindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100
]

{ #category : 'tests' }
WindowsFileLockTest >> testLockShared [
	"Test shared lock"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: 'Test shared lock'.
	stream flush.

	"Lock with shared flag"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 0 length: 100 exclusive: false).

	"Unlock"
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 100)
]

{ #category : 'tests' }
WindowsFileLockTest >> testMultipleLocks [
	"Test locking multiple non-overlapping ranges"

	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	stream := testFile binaryWriteStream.
	stream nextPutAll: '0123456789ABCDEFGHIJ'.
	stream flush.

	"Lock range 0-9"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 0 length: 10).

	"Lock range 10-19 (non-overlapping)"
	self assert: (WindowsFileLock lock: stream fileStream fileHandle from: 10 length: 10).

	"Unlock both ranges"
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 0 length: 10).
	self assert: (WindowsFileLock unlock: stream fileStream fileHandle from: 10 length: 10)
]

{ #category : 'tests' }
WindowsFileLockTest >> testWinOverlappedStructure [
	"Test WinOverlapped structure initialization and field access"

	| overlapped |
	OSPlatform current isWindows ifFalse: [ ^ self skip ].

	overlapped := WinOverlapped new.

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
