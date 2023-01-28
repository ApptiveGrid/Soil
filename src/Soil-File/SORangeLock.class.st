Class {
	#name : #SORangeLock,
	#superclass : #Object,
	#instVars : [
		'from',
		'to',
		'context',
		'stream',
		'registry'
	],
	#category : #'Soil-File'
}

{ #category : #'instance creation' }
SORangeLock class >> from: from length: length context: lockContext [ 
	^ self new 
		from: from;
		to: from + length;
		for: lockContext 
]

{ #category : #'instance creation' }
SORangeLock class >> from: from to: to context: lockContext [ 
	^ self new 
		from: from;
		to: to;
		context: lockContext 
]

{ #category : #'as yet unclassified' }
SORangeLock >> conflictsFrom: aFrom to: aTo context: contextObject [ 
	"conflicts if ranges overlap but only for different contexts"
	^ (self intersectsFrom: from to: to) &  (context ~~ contextObject)
]

{ #category : #'as yet unclassified' }
SORangeLock >> conflictsWith: aSORangeLock [ 
	^ aSORangeLock conflictsFrom: from to: to context: context
]

{ #category : #accessing }
SORangeLock >> context [

	^ context
]

{ #category : #accessing }
SORangeLock >> context: anObject [

	context := anObject
]

{ #category : #accessing }
SORangeLock >> from [

	^ from
]

{ #category : #accessing }
SORangeLock >> from: anObject [

	from := anObject
]

{ #category : #'as yet unclassified' }
SORangeLock >> intersectsFrom: otherFrom to: otherTo [ 
	"other range is before"
	(otherTo < from) ifTrue: [ ^ false ].
	"other range is after"
	(to < otherFrom) ifTrue: [ ^ false ].
	^ true
]

{ #category : #testing }
SORangeLock >> isFrom: aFrom to: aTo for: contextObject [ 
	^ (from = aFrom)& (to = aTo) & (context = contextObject)
]

{ #category : #'as yet unclassified' }
SORangeLock >> lockInMemory: aLockRegistry [ 
	aLockRegistry addLock: self 
	 
]

{ #category : #'as yet unclassified' }
SORangeLock >> lockOn: aStream [ 
	stream := aStream wrappedStream.
	stream lockAt: from length: to - from 
]

{ #category : #printing }
SORangeLock >> printOn: aStream [ 
	aStream << 'range lock  ' 
		<< from asString << ' - ' << to asString.
	registry ifNotNil: [  
		aStream << ' mem ' << registry path asString ].
	stream ifNotNil: [  
		aStream << ' file ' << stream name asString ].
	aStream << ' '.
	context printOn: aStream
]

{ #category : #accessing }
SORangeLock >> registry [

	^ registry
]

{ #category : #accessing }
SORangeLock >> registry: anObject [

	registry := anObject
]

{ #category : #initialization }
SORangeLock >> release [ 
	stream ifNotNil: [ 
		stream unlockAt: from length: to - from.
		stream := nil ].
	registry ifNotNil: [ 
		registry removeLock: self.
		registry := nil ]
]

{ #category : #accessing }
SORangeLock >> stream [

	^ stream
]

{ #category : #accessing }
SORangeLock >> stream: anObject [

	stream := anObject
]

{ #category : #accessing }
SORangeLock >> to [

	^ to
]

{ #category : #accessing }
SORangeLock >> to: anObject [

	to := anObject
]
