Class {
	#name : 'WindowsFileLock',
	#superclass : 'Object',
	#classVars : [
		'ERROR_ACCESS_DENIED',
		'ERROR_INVALID_HANDLE',
		'ERROR_IO_PENDING',
		'ERROR_LOCK_VIOLATION',
		'ERROR_NOT_LOCKED',
		'LOCKFILE_EXCLUSIVE_LOCK',
		'LOCKFILE_FAIL_IMMEDIATELY',
		'LOCKFILE_SHARED_LOCK'
	],
	#category : 'Soil-File',
	#package : 'Soil-File'
}

{ #category : 'testing' }
WindowsFileLock class >> canLock: fileHandle from: start length: length exclusive: exclusive [
	"Windows doesn't have a direct 'test lock' API like F_GETLK.
	We attempt to lock and immediately unlock if successful."

	| success |
	success := self lock: fileHandle from: start length: length exclusive: exclusive.
	success ifTrue: [
		self unlock: fileHandle from: start length: length ].
	^ success
]

{ #category : 'private - error handling' }
WindowsFileLock class >> errorDescription: errorCode [
	"Return a human-readable description for Windows error codes"

	errorCode = ERROR_ACCESS_DENIED ifTrue: [ ^ 'Access denied' ].
	errorCode = ERROR_INVALID_HANDLE ifTrue: [ ^ 'Invalid file handle' ].
	errorCode = ERROR_LOCK_VIOLATION ifTrue: [ ^ 'Lock violation (region already locked)' ].
	errorCode = ERROR_NOT_LOCKED ifTrue: [ ^ 'Region not locked' ].
	errorCode = ERROR_IO_PENDING ifTrue: [ ^ 'I/O operation pending' ].

	^ 'Unknown error (code: ', errorCode printString, ')'
]

{ #category : 'private - ffi' }
WindowsFileLock class >> flushFileBuffers: hFile [
	"Flush all file buffers to disk using Windows API"

	^ self ffiCall: #(bool FlushFileBuffers(void* hFile)) module: #kernel32
]

{ #category : 'private - ffi' }
WindowsFileLock class >> getCurrentProcessId [
	"Get the current process ID using Windows API"

	^ self ffiCall: #(uint GetCurrentProcessId()) module: #kernel32
]

{ #category : 'private - ffi' }
WindowsFileLock class >> getFileHandle: stream [
	"Extract Windows HANDLE from a BinaryFileStream.
	For buffered streams (ZnBufferedWriteStream), get the wrapped file stream first."

	| fileStream |
	fileStream := stream fileStream.
	^ fileStream fileHandle
]

{ #category : 'private - ffi' }
WindowsFileLock class >> getLastError [
	"Get Windows error code"

	^ self ffiCall: #(uint GetLastError()) module: #kernel32
]

{ #category : 'class initialization' }
WindowsFileLock class >> initialize [
	"Windows API constants"

	LOCKFILE_EXCLUSIVE_LOCK := 16r00000002.
	LOCKFILE_FAIL_IMMEDIATELY := 16r00000001.
	LOCKFILE_SHARED_LOCK := 16r00000000.

	"Error codes - from winerror.h"
	ERROR_ACCESS_DENIED := 5.
	ERROR_INVALID_HANDLE := 6.
	ERROR_LOCK_VIOLATION := 33.
	ERROR_NOT_LOCKED := 158.
	ERROR_IO_PENDING := 997
]

{ #category : 'accessing locking' }
WindowsFileLock class >> lock: fileHandle from: start length: length [

	^ self
		lock: fileHandle
		from: start
		length: length
		exclusive: true
]

{ #category : 'accessing locking' }
WindowsFileLock class >> lock: fileHandle from: start length: length exclusive: exclusive [
	"Lock file region, returning true on success, false on failure.
	For detailed error information, use lockOrError:from:length:exclusive:"

	| overlapped flags result lockLow lockHigh |

	"fileHandle is already a Windows HANDLE (ExternalAddress)"

	"Create and initialize OVERLAPPED structure"
	overlapped := WinOverlapped new.
	overlapped offset: (start bitAnd: 16rFFFFFFFF).
	overlapped offsetHigh: (start bitShift: -32).
	overlapped hEvent: ExternalAddress null.

	"Set flags for exclusive or shared lock"
	flags := exclusive
		ifTrue: [ LOCKFILE_EXCLUSIVE_LOCK | LOCKFILE_FAIL_IMMEDIATELY ]
		ifFalse: [ LOCKFILE_SHARED_LOCK | LOCKFILE_FAIL_IMMEDIATELY ].

	"Calculate lock length in low/high parts"
	lockLow := length = 0
		ifTrue: [ 16rFFFFFFFF ]  "0 means lock to EOF"
		ifFalse: [ length bitAnd: 16rFFFFFFFF ].
	lockHigh := length = 0
		ifTrue: [ 16rFFFFFFFF ]
		ifFalse: [ length bitShift: -32 ].

	"Call LockFileEx"
	result := self
		lockFileEx: fileHandle
		flags: flags
		bytesLow: lockLow
		bytesHigh: lockHigh
		overlapped: overlapped.

	"Return success status"
	^ result ~= 0
]

{ #category : 'private - ffi' }
WindowsFileLock class >> lockFileEx: hFile flags: dwFlags bytesLow: nNumberOfBytesToLockLow bytesHigh: nNumberOfBytesToLockHigh overlapped: lpOverlapped [

	^ self
		ffiCall: #(bool LockFileEx(
			void* hFile,
			uint dwFlags,
			uint 0,
			uint nNumberOfBytesToLockLow,
			uint nNumberOfBytesToLockHigh,
			WinOverlapped *lpOverlapped))
		module: #kernel32
]

{ #category : 'accessing locking' }
WindowsFileLock class >> lockOrError: fileHandle from: start length: length exclusive: exclusive [
	"Lock file region, raising an error with detailed information on failure"

	| success errorCode errorDesc lockType |
	success := self lock: fileHandle from: start length: length exclusive: exclusive.

	success ifFalse: [
		errorCode := self getLastError.
		errorDesc := self errorDescription: errorCode.
		lockType := exclusive ifTrue: [ 'exclusive' ] ifFalse: [ 'shared' ].

		Error signal: 'LockFileEx failed: ', lockType, ' lock at offset ', start printString,
			' length ', length printString, ' - ', errorDesc ].

	^ success
]

{ #category : 'accessing locking' }
WindowsFileLock class >> unlock: fileHandle from: start length: length [
	"Unlock file region, returning true on success, false on failure.
	For detailed error information, use unlockOrError:from:length:"

	| overlapped result unlockLow unlockHigh |

	"fileHandle is already a Windows HANDLE (ExternalAddress)"

	"Create and initialize OVERLAPPED structure"
	overlapped := WinOverlapped new.
	overlapped offset: (start bitAnd: 16rFFFFFFFF).
	overlapped offsetHigh: (start bitShift: -32).
	overlapped hEvent: ExternalAddress null.

	"Calculate unlock length in low/high parts"
	unlockLow := length = 0
		ifTrue: [ 16rFFFFFFFF ]
		ifFalse: [ length bitAnd: 16rFFFFFFFF ].
	unlockHigh := length = 0
		ifTrue: [ 16rFFFFFFFF ]
		ifFalse: [ length bitShift: -32 ].

	"Call UnlockFileEx"
	result := self
		unlockFileEx: fileHandle
		bytesLow: unlockLow
		bytesHigh: unlockHigh
		overlapped: overlapped.

	"Return success status"
	^ result ~= 0
]

{ #category : 'private - ffi' }
WindowsFileLock class >> unlockFileEx: hFile bytesLow: nNumberOfBytesToUnlockLow bytesHigh: nNumberOfBytesToUnlockHigh overlapped: lpOverlapped [

	^ self
		ffiCall: #(bool UnlockFileEx(
			void* hFile,
			uint 0,
			uint nNumberOfBytesToUnlockLow,
			uint nNumberOfBytesToUnlockHigh,
			WinOverlapped *lpOverlapped))
		module: #kernel32
]

{ #category : 'accessing locking' }
WindowsFileLock class >> unlockOrError: fileHandle from: start length: length [
	"Unlock file region, raising an error with detailed information on failure"

	| success errorCode errorDesc |
	success := self unlock: fileHandle from: start length: length.

	success ifFalse: [
		errorCode := self getLastError.
		errorDesc := self errorDescription: errorCode.

		Error signal: 'UnlockFileEx failed: unlock at offset ', start printString,
			' length ', length printString, ' - ', errorDesc ].

	^ success
]
