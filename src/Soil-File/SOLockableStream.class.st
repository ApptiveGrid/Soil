Class {
	#name : #SOLockableStream,
	#superclass : #Object,
	#instVars : [
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
	fileStream close.
	self releaseAllLocks 
]

{ #category : #finalization }
SOLockableStream >> finalize [ 
	self releaseAllLocks
]

{ #category : #writing }
SOLockableStream >> flush [
	^ fileStream flush
]

{ #category : #initialization }
SOLockableStream >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	self class finalizationRegistry add: self
]

{ #category : #initialization }
SOLockableStream >> initializePath: aStringOrFileReference [ 
	fileStream := aStringOrFileReference asFileReference binaryReadWriteStream.
	lockRegistry := SOFileLockRegistry forPath: aStringOrFileReference asFileReference 
]

{ #category : #locking }
SOLockableStream >> lockFrom: from length: length for: lockContext [ 
	^ self memoryLockFrom: from to: from + length for: lockContext
]

{ #category : #locking }
SOLockableStream >> lockFrom: from to: to for: lockContext [ 
	self memoryLockFrom: from to: to for: lockContext
]

{ #category : #accessing }
SOLockableStream >> locks [
	^ locks
]

{ #category : #locking }
SOLockableStream >> memoryLockFrom: from length: length for: contextObject [ 
	^ self memoryLockFrom: from to: from + length for: contextObject  
]

{ #category : #locking }
SOLockableStream >> memoryLockFrom: from to: to for: contextObject [ 
	^ locks add: (lockRegistry lockFrom: from to: to for: contextObject)
]

{ #category : #locking }
SOLockableStream >> memoryUnlockFrom: from length: length for: contextObject [ 
	^ self memoryUnlockFrom: from to: from + length for: contextObject  
]

{ #category : #locking }
SOLockableStream >> memoryUnlockFrom: from to: to for: contextObject [ 
	locks remove: (lockRegistry unlockFrom: from to: to for: contextObject)
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
	(lockRegistry notNil & locks notNil) ifTrue: [  
		locks do: [ :lock | 
			lockRegistry removeLock: lock ].
		locks := nil ].
]

{ #category : #accessing }
SOLockableStream >> size [ 
	^ fileStream size
]
