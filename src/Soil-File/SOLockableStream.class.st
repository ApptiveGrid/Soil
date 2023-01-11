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

{ #category : #accessing }
SOLockableStream >> locks [
	^ locks
]

{ #category : #locking }
SOLockableStream >> memoryLockFrom: from to: to for: contextObject [ 
	locks add: (lockRegistry lockFrom: from to: to for: contextObject)
]

{ #category : #locking }
SOLockableStream >> memoryUnlockFrom: from to: to for: contextObject [ 
	locks remove: (lockRegistry unlockFrom: from to: to for: contextObject)
]

{ #category : #writing }
SOLockableStream >> nextPutAll: aString [ 
	fileStream nextPutAll: aString 
]

{ #category : #finalization }
SOLockableStream >> releaseAllLocks [
	(lockRegistry notNil & locks notNil) ifTrue: [  
		locks do: [ :lock | 
			lockRegistry removeLock: lock ].
		locks := nil ].
]
