Class {
	#name : #SOFileLockRegistry,
	#superclass : #Object,
	#instVars : [
		'locks',
		'semaphore'
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
			ifAbsentPut: [ self new ] ]
]

{ #category : #initialization }
SOFileLockRegistry class >> initialize [ 
	self reset
]

{ #category : #'as yet unclassified' }
SOFileLockRegistry class >> numberOfRegistries [
	^ registries size
]

{ #category : #initialization }
SOFileLockRegistry class >> reset [ 
	accessSemaphore := Semaphore forMutualExclusion.
	registries := WeakValueDictionary new
]

{ #category : #initialization }
SOFileLockRegistry >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion
]

{ #category : #accessing }
SOFileLockRegistry >> lockFrom: from to: to for: currentLockingObject [ 
	^ semaphore critical: [  
		locks 
			detect: [:lock | lock conflictsFrom: from to: to context: currentLockingObject ]
			ifFound: [:lock | SOAlreadyLocked signal: 'already locked: ', lock asString  ].
		locks 
			add: (SORangeLock new 
				from: from;
				to: to;
				context: currentLockingObject) ]
]

{ #category : #accessing }
SOFileLockRegistry >> numberOfLocks [
	^ locks size
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
