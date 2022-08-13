Class {
	#name : #SOBSDFLock,
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
	#category : #'Soil-Core'
}

{ #category : #testing }
SOBSDFLock class >> canLock: fileHandle from: start to: length exclusive: exclusive [
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
SOBSDFLock class >> fcntl: fd command: cmd struct: struct [
	^ self 
		ffiCall: #(int fcntl(int fd, int cmd, FLock *struct)) 
		library: LibC
		fixedArgumentCount: 2
]

{ #category : #private }
SOBSDFLock class >> fcntl: fd command: cmd value: value [

	^ self 
		ffiCall: #(int fcntl(int fd, int cmd, ulong value))
		library: LibC
		fixedArgumentCount: 2
]

{ #category : #'field definition' }
SOBSDFLock class >> fieldsDesc [
	"self rebuildFieldAccessors"

	^ #(
	__off64_t l_start;
	__off64_t l_len;
	__pid_t l_pid;	
	int l_type;
	int l_whence;
	)
]

{ #category : #private }
SOBSDFLock class >> fileno: stream [

	^ self 
		ffiCall: #(int fileno("FILE *"void *stream))
		module: LibC
]

{ #category : #private }
SOBSDFLock class >> flock: fd operation: operation [

	^ self 
		ffiCall: #(int flock(int fd, int operation))
		module: LibC
]

{ #category : #private }
SOBSDFLock class >> getpid [

	^ self ffiCall: #(__pid_t getpid()) module: LibC
]

{ #category : #'class initialization' }
SOBSDFLock class >> initialize [

	__off64_t := FFIUInt64.
	__pid_t := FFIUInt32.
	
	F_RDLCK := 1.
	F_UNLCK := 2.
	F_WRLCK := 3.
	
	SEEK_SET := 0.
	SEEK_CUR := 1.
	SEEK_END := 2.
	
	F_GETLK := 7. "12?"
	F_SETLK := 8. "13?"
	F_SETLKW := 9. "14?"
	
	F_GETFL := 3.
	F_SETFL := 4.
	
	O_NONBLOCK := 8r4000
]

{ #category : #'accessing locking' }
SOBSDFLock class >> lock: fileHandle from: start to: length [
	
	^ self 
		lock: fileHandle 
		from: start 
		to: length
		exclusive: true
]

{ #category : #'accessing locking' }
SOBSDFLock class >> lock: fileHandle from: start to: length exclusive: exclusive [
	| lock result |
	
	lock := self newLockExclusive: exclusive start: start length: length.
	result := self 
		fcntl: (self fileno: fileHandle) 
		command: F_SETLK 
		struct: lock.
		
	^ result ~= -1
]

{ #category : #'instance creation' }
SOBSDFLock class >> newLockExclusive: exclusive start: start length: length [
	
	^ self 
		newType: (exclusive ifTrue: [ F_WRLCK ] ifFalse: [ F_RDLCK ])
		start: start
		length: length
]

{ #category : #'instance creation' }
SOBSDFLock class >> newType: type start: start length: length [
	
	^ self new 
		l_type: type;
		l_whence: SEEK_SET;
		l_start: start;
		l_len: length;
		l_pid:  self getpid;
		yourself
]

{ #category : #'instance creation' }
SOBSDFLock class >> newUnlockStart: start length: length [
	
	^ self 
		newType: F_UNLCK
		start: start
		length: length
]

{ #category : #accessing }
SOBSDFLock class >> setNonBlock: fileHandle [
	| fd flags |
	
	fd := self fileno: fileHandle.
	
	flags := self fcntl: fd command: F_GETFL value: 0.
	flags := self fcntl: fd command: F_SETFL value: flags | O_NONBLOCK
]

{ #category : #'accessing locking' }
SOBSDFLock class >> unlock: fileHandle from: start to: length [
	| lock result |
	
	lock := self newUnlockStart: start length: length.
	result := self 
		fcntl: (self fileno: fileHandle) 
		command: F_SETLK 
		struct: lock.
		
	^ result ~= -1
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_len [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_L_LEN
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_len: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_L_LEN put: anObject
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_pid [
	"This method was automatically generated"
	^handle unsignedLongAt: OFFSET_L_PID
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_pid: anObject [
	"This method was automatically generated"
	handle unsignedLongAt: OFFSET_L_PID put: anObject
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_start [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_L_START
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_start: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_L_START put: anObject
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_type [
	"This method was automatically generated"
	^handle signedLongAt: OFFSET_L_TYPE
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_type: anObject [
	"This method was automatically generated"
	handle signedLongAt: OFFSET_L_TYPE put: anObject
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_whence [
	"This method was automatically generated"
	^handle signedLongAt: OFFSET_L_WHENCE
]

{ #category : #'accessing - structure variables' }
SOBSDFLock >> l_whence: anObject [
	"This method was automatically generated"
	handle signedLongAt: OFFSET_L_WHENCE put: anObject
]

{ #category : #printing }
SOBSDFLock >> printOn: aStream [ 
	"Append to the argument, aStream, the names and values of all the record's variables."

	aStream nextPutAll: self class name; nextPutAll: ' ( '; cr.
	self class fieldSpec fieldNames do: [ :field |
		aStream nextPutAll: field; nextPut: $:; space; tab.
			(self perform: field ) printOn: aStream.
			] separatedBy: [ aStream cr ].
	aStream cr; nextPut: $)
]
