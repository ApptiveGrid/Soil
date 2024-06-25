Class {
	#name : #SoilLockableStream,
	#superclass : #Object,
	#instVars : [
		'imageLocked',
		'fileLocked',
		'fileStream',
		'lockRegistry',
		'locks'
	],
	#classInstVars : [
		'defaultImageLocked',
		'defaultFileLocked'
	],
	#category : #'Soil-File'
}

{ #category : #accessing }
SoilLockableStream class >> defaultFileLocked [
	^ defaultFileLocked ifNil: [ true ]
]

{ #category : #accessing }
SoilLockableStream class >> defaultFileLocked: aBoolean [ 
	defaultFileLocked := aBoolean 
]

{ #category : #accessing }
SoilLockableStream class >> defaultImageLocked [
	^ defaultImageLocked ifNil: [ true ]
]

{ #category : #accessing }
SoilLockableStream class >> defaultImageLocked: aBoolean [ 
	defaultImageLocked := aBoolean 
]

{ #category : #'instance creation' }
SoilLockableStream class >> path: aStringOrFileReference [ 
	^ self new 
		initializePath: aStringOrFileReference;
		yourself
]

{ #category : #accessing }
SoilLockableStream >> atEnd [
	^ fileStream atEnd
]

{ #category : #'open/close' }
SoilLockableStream >> close [
	self releaseAllLocks.
	fileStream ifNotNil: [  
		fileStream closed 
			ifFalse: [ fileStream close ] ].

]

{ #category : #accessing }
SoilLockableStream >> defaultFileLocked [
	^ self class defaultFileLocked 
]

{ #category : #accessing }
SoilLockableStream >> defaultImageLocked [
	^ self class defaultImageLocked 
]

{ #category : #accessing }
SoilLockableStream >> fileLocked [ 
	^ fileLocked ifNil: [ 
		fileLocked := self defaultFileLocked  ]
]

{ #category : #accessing }
SoilLockableStream >> fileStream [
	^ fileStream fileStream
]

{ #category : #finalization }
SoilLockableStream >> finalize [ 
	self close
]

{ #category : #writing }
SoilLockableStream >> flush [
	^ fileStream flush
]

{ #category : #accessing }
SoilLockableStream >> imageLocked [ 
	^ imageLocked ifNil: [ 
		imageLocked := self defaultImageLocked  ]
]

{ #category : #initialization }
SoilLockableStream >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	self class finalizationRegistry add: self.
	imageLocked := true.
	fileLocked := true.
]

{ #category : #initialization }
SoilLockableStream >> initializePath: aStringOrFileReference [ 
	fileStream := aStringOrFileReference asFileReference binaryReadWriteStream.
	lockRegistry := SoilFileLockRegistry forPath: aStringOrFileReference asFileReference 
]

{ #category : #testing }
SoilLockableStream >> isOpen [
	^fileStream closed not
]

{ #category : #locking }
SoilLockableStream >> lockAppendingFor: lockContext [
	^ self registerLock: (self lockClass from: 0 to: 0 context: lockContext)

]

{ #category : #locking }
SoilLockableStream >> lockClass [
	^ SoilRangeLock 
]

{ #category : #locking }
SoilLockableStream >> lockFrom: from length: length for: lockContext [ 
	
	^ self registerLock: (self lockClass from: from length: length context: lockContext)

]

{ #category : #locking }
SoilLockableStream >> lockFrom: from to: to for: lockContext [ 

	^ self registerLock: (self lockClass from: from to: to context: lockContext)

]

{ #category : #initialization }
SoilLockableStream >> lockOnlyInImage [
	imageLocked := true.
	fileLocked := false.
]

{ #category : #accessing }
SoilLockableStream >> locks [
	^ locks
]

{ #category : #reading }
SoilLockableStream >> next [
	^ fileStream next 
]

{ #category : #reading }
SoilLockableStream >> next: anInteger [ 
	^ fileStream next: anInteger 
]

{ #category : #'reading - basic' }
SoilLockableStream >> nextLengthEncodedInteger [
	| value |
	value := self next.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #writing }
SoilLockableStream >> nextPut: anInteger [ 
	fileStream nextPut: anInteger
]

{ #category : #writing }
SoilLockableStream >> nextPutAll: aString [ 
	fileStream nextPutAll: aString 
]

{ #category : #'writing - basic' }
SoilLockableStream >> nextPutLengthEncodedInteger: anInteger [ 
	fileStream nextPutLengthEncodedInteger: anInteger 
]

{ #category : #accessing }
SoilLockableStream >> peek [
	^ fileStream  peek
]

{ #category : #positioning }
SoilLockableStream >> position [
	^ fileStream position
]

{ #category : #positioning }
SoilLockableStream >> position: anInteger [ 
	fileStream position: anInteger 
]

{ #category : #accessing }
SoilLockableStream >> readInto: aCollection startingAt: startIndex count: count [ 
	^ fileStream readInto: aCollection startingAt: startIndex count: count 
]

{ #category : #locking }
SoilLockableStream >> registerLock: lock [
	
	imageLocked ifTrue: [ 
		lock lockInMemory: lockRegistry ].
	
	fileLocked ifTrue: [ 
		lock lockOn: self  ].
	
	^ locks add: lock
	
]

{ #category : #finalization }
SoilLockableStream >> releaseAllLocks [
	locks copy do: [ :lock | 
		lock release ].
	locks := OrderedCollection new
]

{ #category : #initialization }
SoilLockableStream >> setToEnd [
	fileStream setToEnd 
]

{ #category : #accessing }
SoilLockableStream >> size [ 
	^ fileStream size
]

{ #category : #locking }
SoilLockableStream >> unlockFrom: from to: to for: lockContext [ 
	
	| lock |
	lock := locks 
		detect: [ :each | 
			(each from = from) and: [ (each to = to) and: [ each context = lockContext ] ] ]
		ifNone: [ NotFound signal: 'cannot find lock' ].
	fileStream wrappedStream unlockAt: from length: to - from. 
	locks remove: lock
	
]
