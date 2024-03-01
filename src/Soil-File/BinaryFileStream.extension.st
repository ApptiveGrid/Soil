Extension { #name : #BinaryFileStream }

{ #category : #'*Soil-File' }
BinaryFileStream >> fdataSync: fd [
	^ self 
		ffiCall: #(int fdatasync(int fd))
		module: LibC
]

{ #category : #'*Soil-File' }
BinaryFileStream >> fdatasync [ 
	| fd err |
	fd := self fileno.
	err := self fdataSync: self fileno.
	(err = 0) ifFalse: [ 
		Error signal: 'fdatasync(', fd printString, ') failed with error code: ', err printString ]
]

{ #category : #'*Soil-File' }
BinaryFileStream >> fileHandle [

	^ handle pointerAt: 9
]

{ #category : #'*Soil-File' }
BinaryFileStream >> fileno [

	| fd |
	fd := self fileno: self fileHandle.
	(fd = -1) ifTrue: [ 
		Error signal: 'cannot get file descriptor for ', self name, ': error = ', ((ExternalAddress loadSymbol: #errno) signedLongAt: 1) printString].
	^ fd
	
]

{ #category : #'*Soil-File' }
BinaryFileStream >> fileno: stream [

	^ self 
		ffiCall: #(int fileno("FILE *"void *stream))
		module: LibC
]

{ #category : #'*Soil-File' }
BinaryFileStream >> flockClass [
	^ OSPlatform current flockClass
]

{ #category : #'*Soil-File' }
BinaryFileStream >> lockAt: position length: length [
	^ self flockClass
		lock: self fileHandle
		from: position
		length: length
]

{ #category : #'*Soil-File' }
BinaryFileStream >> lockEntireFile [
	^ self flockClass
		lock: self fileHandle
		from: 0
		length: self size
]

{ #category : #'*Soil-File' }
BinaryFileStream >> lockEntireFileAndBeyond [
	"add a lock for appending to a file. We use the whole file starting
	at 0 to have reliable semantics. Using the end of the file might be more
	accurate but unlocking would be difficult because after appending the 
	size of the file has changed"
	^ self flockClass
		lock: self fileHandle
		from: 0
		length: 0
]

{ #category : #'*Soil-File' }
BinaryFileStream >> lockForAppendStartingAt: offset [
	"add append lock by taking an offset. Having an append lock and matching
	unlock is not possible from within this stream so the offset needs to be
	provided"
	^ self flockClass
		lock: self fileHandle
		from: offset
		length: 0
]

{ #category : #'*Soil-File' }
BinaryFileStream >> sync [ 
	^ self sync: (self fileno: self fileHandle).
	
]

{ #category : #'*Soil-File' }
BinaryFileStream >> sync: fd [
	^ self 
		ffiCall: #(int fsync(int fd))
		module: LibC
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlockAt: position length: length [

	^ self flockClass
		unlock: self fileHandle
		from: position
		length: length
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlockEntireFile [
	^ self flockClass
		unlock: self fileHandle
		from: 0
		length: self size
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlockEntireFileAndBeyond [
	"release a lock for appending to a file. We use the whole file starting
	at 0 to have reliable semantics. The end of the file might have changed 
	since the lock was set. Releasing the same region that was used for locking
	avoids subtle problems"
	^ self flockClass
		lock: self fileHandle
		from: 0
		length: 0
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlockForAppendStartingAt: offset [
	"release append lock by taking an offset. Having an append lock and matching
	unlock is not possible from within this stream so the offset needs to be
	provided"
	^ self flockClass
		unlock: self fileHandle
		from: offset
		length: 0
]
