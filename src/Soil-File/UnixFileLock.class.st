Class {
	#name : #UnixFileLock,
	#superclass : #FFIStructure,
	#classVars : [
		'F_GETFL',
		'F_GETLK',
		'F_RDLCK',
		'F_SETFL',
		'F_SETLK',
		'F_SETLKW',
		'F_UNLCK',
		'F_WRLCK',
		'OFFSET_L_LEN',
		'OFFSET_L_PID',
		'OFFSET_L_START',
		'OFFSET_L_TYPE',
		'OFFSET_L_WHENCE',
		'O_NONBLOCK',
		'SEEK_CUR',
		'SEEK_END',
		'SEEK_SET',
		'__off64_t',
		'__pid_t'
	],
	#category : #'Soil-File'
}

{ #category : #testing }
UnixFileLock class >> canLock: fileHandle from: start length: length exclusive: exclusive [
	| lock result |
	
	lock := self newLockExclusive: exclusive start: start length: length.
	result := self 
		fcntl: (self fileno: fileHandle) 
		command: F_GETLK 
		struct: lock.
		
	 result = -1 ifTrue: [ ^ false ].
	^ lock l_type = F_UNLCK
]

{ #category : #private }
UnixFileLock class >> fcntl: fd command: cmd struct: struct [

	^ self 
		ffiCall: #(int fcntl(int fd, int cmd, UnixFileLock *struct))
		library: LibC
		fixedArgumentCount: 2
]

{ #category : #private }
UnixFileLock class >> fcntl: fd command: cmd value: value [

	^ self 
		ffiCall: #(int fcntl(int fd, int cmd, int value))
		library: LibC
		fixedArgumentCount: 2
]

{ #category : #'field definition' }
UnixFileLock class >> fieldsDesc [
	"self rebuildFieldAccessors"

	^ #(
	short l_type;
	short l_whence;
	__off64_t l_start;
	__off64_t l_len;
	__pid_t l_pid;	
	)
]

{ #category : #private }
UnixFileLock class >> fileno: stream [

	^ self 
		ffiCall: #(int fileno("FILE *"void *stream))
		module: LibC
]

{ #category : #private }
UnixFileLock class >> flock: fd operation: operation [

	^ self 
		ffiCall: #(int flock(int fd, int operation))
		module: LibC
]

{ #category : #private }
UnixFileLock class >> getpid [

	^ self ffiCall: #(__pid_t getpid()) module: LibC
]

{ #category : #'class initialization' }
UnixFileLock class >> initialize [

	__off64_t := FFIUInt64.
	__pid_t := FFIUInt32.
	
	F_RDLCK := 0.
	F_WRLCK := 1.
	F_UNLCK := 2.
	
	SEEK_SET := 0.
	SEEK_CUR := 1.
	SEEK_END := 2.
	
	F_GETLK := 5. "12?"
	F_SETLK := 6. "13?"
	F_SETLKW := 7. "14?"
	
	F_GETFL := 3.
	F_SETFL := 4.
	
	O_NONBLOCK := 8r4000
]

{ #category : #'accessing locking' }
UnixFileLock class >> lock: fileHandle from: start length: length [
	
	^ self 
		lock: fileHandle 
		from: start 
		length: length
		exclusive: true
]

{ #category : #'accessing locking' }
UnixFileLock class >> lock: fileHandle from: start length: length exclusive: exclusive [
	| lock result |
	
	lock := self newLockExclusive: exclusive start: start length: length.
	result := self 
		fcntl: (self fileno: fileHandle) 
		command: F_SETLK 
		struct: lock.
		
	^ result ~= -1
]

{ #category : #'instance creation' }
UnixFileLock class >> newLockExclusive: exclusive start: start length: length [
	
	^ self 
		newType: (exclusive ifTrue: [ F_WRLCK ] ifFalse: [ F_RDLCK ])
		start: start
		length: length
]

{ #category : #'instance creation' }
UnixFileLock class >> newType: type start: start length: length [
	
	^ self new 
		l_type: type;
		l_whence: SEEK_SET;
		l_start: start;
		l_len: length;
		l_pid:  self getpid;
		yourself
]

{ #category : #'instance creation' }
UnixFileLock class >> newUnlockStart: start length: length [
	
	^ self 
		newType: F_UNLCK
		start: start
		length: length
]

{ #category : #accessing }
UnixFileLock class >> setNonBlock: fileHandle [
	| fd flags |
	
	fd := self fileno: fileHandle.
	
	flags := self fcntl: fd command: F_GETFL value: 0.
	flags := self fcntl: fd command: F_SETFL value: flags | O_NONBLOCK
]

{ #category : #'accessing locking' }
UnixFileLock class >> unlock: fileHandle from: start length: length [
	| lock result |
	
	lock := self newUnlockStart: start length: length.
	result := self 
		fcntl: (self fileno: fileHandle) 
		command: F_SETLK 
		struct: lock.
		
	^ result ~= -1
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_len [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_L_LEN
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_len: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_L_LEN put: anObject
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_pid [
	"This method was automatically generated"
	^handle unsignedLongAt: OFFSET_L_PID
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_pid: anObject [
	"This method was automatically generated"
	handle unsignedLongAt: OFFSET_L_PID put: anObject
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_start [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_L_START
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_start: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_L_START put: anObject
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_type [
	"This method was automatically generated"
	^handle signedShortAt: OFFSET_L_TYPE
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_type: anObject [
	"This method was automatically generated"
	handle signedShortAt: OFFSET_L_TYPE put: anObject
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_whence [
	"This method was automatically generated"
	^handle signedShortAt: OFFSET_L_WHENCE
]

{ #category : #'accessing structure variables' }
UnixFileLock >> l_whence: anObject [
	"This method was automatically generated"
	handle signedShortAt: OFFSET_L_WHENCE put: anObject
]

{ #category : #printing }
UnixFileLock >> printOn: aStream [ 
	"Append to the argument, aStream, the names and values of all the record's variables."

	aStream nextPutAll: self class name; nextPutAll: ' ( '; cr.
	self class fieldSpec fieldNames do: [ :field |
		aStream nextPutAll: field; nextPut: $:; space; tab.
			(self perform: field ) printOn: aStream.
			] separatedBy: [ aStream cr ].
	aStream cr; nextPut: $)
]
