Class {
	#name : #SORangeLock,
	#superclass : #Object,
	#instVars : [
		'from',
		'to',
		'context'
	],
	#category : #'Soil-File'
}

{ #category : #'as yet unclassified' }
SORangeLock >> conflictsFrom: aFrom to: aTo context: contextObject [ 
	"conflicts if ranges overlap but only for different contexts"
	^ (self intersectsFrom: from to: to) &  (context ~~ contextObject)
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

{ #category : #printing }
SORangeLock >> printOn: aStream [ 
	aStream << 'lock range ' << from asString << ' - ' << to asString << ' by '.
	context printOn: aStream
]

{ #category : #accessing }
SORangeLock >> to [

	^ to
]

{ #category : #accessing }
SORangeLock >> to: anObject [

	to := anObject
]
