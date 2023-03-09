Class {
	#name : #SOObjectId,
	#superclass : #Object,
	#instVars : [
		'segment',
		'index'
	],
	#classVars : [
		'RootObjectId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #examples }
SOObjectId class >> example [
	<sampleInstance>

	^ self segment: 1 index: 3
]

{ #category : #'instance creation' }
SOObjectId class >> readFrom: stream [ 
	"for now fix the segment id to be the 16 upper bits and the index 
	be 48 lower bits"
	^ self new 
		segment: (stream next: 2) asInteger;
		index: (stream next: 6) asInteger
]

{ #category : #'instance creation' }
SOObjectId class >> root [
	^ RootObjectId ifNil: [ RootObjectId := self segment: 1 index: 1 ]
]

{ #category : #'instance creation' }
SOObjectId class >> segment: segmentId index: index [
	^ self new 
		segment: segmentId index: index
]

{ #category : #comparing }
SOObjectId >> = anObjectId [ 
	(anObjectId class = self class) ifFalse: [ ^ false ].
	"object ids are generated with zero as index because the allocation of the 
	real index needs to be done on commit time"
	(index = 0) ifTrue: [ ^ self == anObjectId ].
	^ segment = anObjectId segment and: [ 
		index = anObjectId index ]
]

{ #category : #converting }
SOObjectId >> asByteArray [
	^ (segment asByteArrayOfSize: 2), (index asByteArrayOfSize: 6)
]

{ #category : #converting }
SOObjectId >> asByteArrayOfSize: anInteger [ 
	(anInteger = 8) ifFalse: [ self halt ].
	^ self asByteArray 
]

{ #category : #comparing }
SOObjectId >> hash [ 
	^ segment hash bitXor: index hash
]

{ #category : #accessing }
SOObjectId >> index [
	^ index
]

{ #category : #accessing }
SOObjectId >> index: anInteger [
	index := anInteger 
]

{ #category : #initialization }
SOObjectId >> initialize [ 
	super initialize.
	segment := 1
]

{ #category : #initialization }
SOObjectId >> initializeIndex: objectRepository [ 
	(index = 0) ifFalse: [ ^ self ].
	index := (objectRepository segmentAt: segment) allocateNextIndex 
]

{ #category : #testing }
SOObjectId >> isInitialized [
	^ index > 0
]

{ #category : #printing }
SOObjectId >> printOn: aStream [ 
	aStream << 'ObjectId(' << segment asString << ':' << index asString << ')'
]

{ #category : #accessing }
SOObjectId >> segment [
	self flag: #todo.
	"There should ne no default segment. This is a shortcut"
	^ segment ifNil: [ 1 ]
]

{ #category : #accessing }
SOObjectId >> segment: anInteger [ 
	segment := anInteger  
	
]

{ #category : #accessing }
SOObjectId >> segment: segmentNo index: segmentIndex [ 
	segment := segmentNo.
	index := segmentIndex 
]

{ #category : #accessing }
SOObjectId >> setIndex: anInteger [ 
	index := anInteger 
]

{ #category : #'as yet unclassified' }
SOObjectId >> writeOn: aStream [ 
	"for now fix the segment id to be the 16 upper bits and the index 
	be 48 lower bits"
	aStream 
		nextPutAll: (segment asByteArrayOfSize: 2);
		nextPutAll: (index asByteArrayOfSize: 6)
]
