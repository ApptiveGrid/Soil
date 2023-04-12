Class {
	#name : #SoilFileLockRegistry,
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
SoilFileLockRegistry class >> forPath: aString [ 
	^ accessSemaphore critical: [ 
		registries 
			at: aString asPath canonicalize
			ifAbsentPut: [ self new
				path: aString ] ]
]

{ #category : #initialization }
SoilFileLockRegistry class >> initialize [ 
	self reset
]

{ #category : #'as yet unclassified' }
SoilFileLockRegistry class >> numberOfRegistries [
	^ registries size
]

{ #category : #accessing }
SoilFileLockRegistry class >> registries [ 
	^ registries 
]

{ #category : #initialization }
SoilFileLockRegistry class >> reset [ 
	accessSemaphore := Semaphore forMutualExclusion.
	registries := WeakValueDictionary new
]

{ #category : #adding }
SoilFileLockRegistry >> addLock: aLock [
	aLock registry: self.
	^ semaphore critical: [  
		locks 
			detect: [:lock | lock conflictsWith: aLock ]
			ifFound: [:lock | SoilAlreadyLocked signal: 'cannot lock <', aLock asString, '> because is locked by  <', lock asString,'>'  ].
		locks add: aLock ]
	
]

{ #category : #initialization }
SoilFileLockRegistry >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion
]

{ #category : #accessing }
SoilFileLockRegistry >> lockFrom: from to: to for: currentLockingObject [ 
	^ self addLock: (SoilRangeLock from: from to: to context: currentLockingObject)
]

{ #category : #accessing }
SoilFileLockRegistry >> numberOfLocks [
	^ locks size
]

{ #category : #accessing }
SoilFileLockRegistry >> path [

	^ path
]

{ #category : #accessing }
SoilFileLockRegistry >> path: anObject [

	path := anObject
]

{ #category : #printing }
SoilFileLockRegistry >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ' locks=' << locks size asString << ',path: ' << path asString 
]

{ #category : #removing }
SoilFileLockRegistry >> removeLock: aSORangeLock [ 
	semaphore critical: [ 
		locks remove: aSORangeLock ]
]

{ #category : #'as yet unclassified' }
SoilFileLockRegistry >> unlockFrom: from to: to for: contextObject [ 
	| lock |
	^ semaphore critical: [  
		lock := locks 
			detect: [ :each | each isFrom: from to: to for: contextObject ]
			ifNone: [ SoilLockNotFound signal: 'cannot find lock from ', from asString, ' to ', to asString , ' for ', contextObject asString ].
		locks remove: lock ]
]
