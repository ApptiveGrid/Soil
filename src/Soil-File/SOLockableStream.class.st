Class {
	#name : #SOLockableStream,
	#superclass : #Object,
	#instVars : [
		'imageLocked',
		'fileLocked',
		'fileStream',
		'lockRegistry',
		'locks'
	],
	#category : #'Soil-File'
}

{ #category : #'instance creation' }
SOLockableStream class >> path: aStringOrFileReference [ 
	^ self new 
		initializePath: aStringOrFileReference;
		yourself
]

{ #category : #'initialize-release' }
SOLockableStream >> close [
	self releaseAllLocks.
	fileStream ifNotNil: [  
		fileStream closed 
			ifFalse: [ fileStream close ] ].

]

{ #category : #finalization }
SOLockableStream >> finalize [ 
	self close
]

{ #category : #writing }
SOLockableStream >> flush [
	^ fileStream flush
]

{ #category : #initialization }
SOLockableStream >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	self class finalizationRegistry add: self.
	imageLocked := true.
	fileLocked := true.
]

{ #category : #initialization }
SOLockableStream >> initializePath: aStringOrFileReference [ 
	fileStream := aStringOrFileReference asFileReference binaryReadWriteStream.
	lockRegistry := SOFileLockRegistry forPath: aStringOrFileReference asFileReference 
]

{ #category : #locking }
SOLockableStream >> lockAppendingFor: lockContext [
	^ self registerLock: (self lockClass from: 0 to: 0 context: lockContext)

]

{ #category : #locking }
SOLockableStream >> lockClass [
	^ SORangeLock 
]

{ #category : #locking }
SOLockableStream >> lockFrom: from length: length for: lockContext [ 
	
	^ self registerLock: (self lockClass from: from length: length context: lockContext)

]

{ #category : #locking }
SOLockableStream >> lockFrom: from to: to for: lockContext [ 

	^ self registerLock: (self lockClass from: from to: to context: lockContext)

]

{ #category : #'as yet unclassified' }
SOLockableStream >> lockOnlyInImage [
	imageLocked := true.
	fileLocked := false.
]

{ #category : #accessing }
SOLockableStream >> locks [
	^ locks
]

{ #category : #reading }
SOLockableStream >> next [
	^ fileStream next 
]

{ #category : #reading }
SOLockableStream >> next: anInteger [ 
	^ fileStream next: anInteger 
]

{ #category : #writing }
SOLockableStream >> nextPut: anInteger [ 
	fileStream nextPut: anInteger
]

{ #category : #writing }
SOLockableStream >> nextPutAll: aString [ 
	fileStream nextPutAll: aString 
]

{ #category : #positioning }
SOLockableStream >> position [
	^ fileStream position
]

{ #category : #positioning }
SOLockableStream >> position: anInteger [ 
	fileStream position: anInteger 
]

{ #category : #locking }
SOLockableStream >> registerLock: lock [
	
	imageLocked ifTrue: [ 
		lock lockInMemory: lockRegistry ].
	
	fileLocked ifTrue: [ 
		lock lockOn: fileStream  ].
	
	^ locks add: lock
	
]

{ #category : #finalization }
SOLockableStream >> releaseAllLocks [
	locks copy do: [ :lock | 
		locks remove: lock.
		lock release ].
	locks := OrderedCollection new
]

{ #category : #accessing }
SOLockableStream >> size [ 
	^ fileStream size
]

{ #category : #locking }
SOLockableStream >> unlockFrom: from to: to for: lockContext [ 
	
	| lock |
	lock := locks 
		detect: [ :each | 
			(each from = from) & (each to = to) & (each context = lockContext) ]
		ifNone: [ NotFound signal: 'cannot find lock' ].
	lock release.
	locks remove: lock
	
]
