Class {
	#name : #SOFileLockRegistry,
	#superclass : #Object,
	#instVars : [
		'locks',
		'semaphore',
		'path'
	],
	#classInstVars : [
		'registries',
		'accessSemaphore'
	],
	#category : #'Soil-File'
}

{ #category : #registry }
SOFileLockRegistry class >> forPath: aString [ 
	^ accessSemaphore critical: [ 
		registries 
			at: aString asPath canonicalize
			ifAbsentPut: [ self new
				path: aString ] ]
]

{ #category : #initialization }
SOFileLockRegistry class >> initialize [ 
	self reset
]

{ #category : #'as yet unclassified' }
SOFileLockRegistry class >> numberOfRegistries [
	^ registries size
]

{ #category : #accessing }
SOFileLockRegistry class >> registries [ 
	^ registries 
]

{ #category : #initialization }
SOFileLockRegistry class >> reset [ 
	accessSemaphore := Semaphore forMutualExclusion.
	registries := WeakValueDictionary new
]

{ #category : #adding }
SOFileLockRegistry >> addLock: aLock [
	aLock registry: self.
	^ semaphore critical: [  
		locks 
			detect: [:lock | lock conflictsWith: aLock ]
			ifFound: [:lock | SOAlreadyLocked signal: 'cannot lock <', aLock asString, '> because is locked by  <', lock asString,'>'  ].
		locks add: aLock ]
	
]

{ #category : #initialization }
SOFileLockRegistry >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion
]

{ #category : #accessing }
SOFileLockRegistry >> lockFrom: from to: to for: currentLockingObject [ 
	^ self addLock: (SORangeLock from: from to: to context: currentLockingObject)
]

{ #category : #accessing }
SOFileLockRegistry >> numberOfLocks [
	^ locks size
]

{ #category : #accessing }
SOFileLockRegistry >> path [

	^ path
]

{ #category : #accessing }
SOFileLockRegistry >> path: anObject [

	path := anObject
]

{ #category : #printing }
SOFileLockRegistry >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ' locks=' << locks size asString << ',path: ' << path asString 
]

{ #category : #removing }
SOFileLockRegistry >> removeLock: aSORangeLock [ 
	semaphore critical: [ 
		locks remove: aSORangeLock ]
]

{ #category : #'as yet unclassified' }
SOFileLockRegistry >> unlockFrom: from to: to for: contextObject [ 
	| lock |
	^ semaphore critical: [  
		lock := locks 
			detect: [ :each | each isFrom: from to: to for: contextObject ]
			ifNone: [ SOLockNotFound signal: 'cannot find lock from ', from asString, ' to ', to asString , ' for ', contextObject asString ].
		locks remove: lock ]
]
