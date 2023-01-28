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
		fileStream close ].

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
SOLockableStream >> lockClass [
	^ SORangeLock 
]

{ #category : #locking }
SOLockableStream >> lockFrom: from length: length for: lockContext [ 
	^ self lockFrom: from to: from + length for: lockContext
]

{ #category : #locking }
SOLockableStream >> lockFrom: from to: to for: lockContext [ 
	
	| lock |
	lock := self lockClass from: from to: to context: lockContext.

	imageLocked ifTrue: [ 
		lock lockInMemory: lockRegistry ].
	
	fileLocked ifTrue: [ 
		lock lockOn: fileStream  ].
	
	^ locks add: lock
	
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

{ #category : #finalization }
SOLockableStream >> releaseAllLocks [
	locks do: [ :lock | lock release ].
	locks := OrderedCollection new
]

{ #category : #accessing }
SOLockableStream >> size [ 
	^ fileStream size
]
