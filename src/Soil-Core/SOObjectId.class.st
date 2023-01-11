Class {
	#name : #SOObjectId,
	#superclass : #Object,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #examples }
SOObjectId class >> example [
	<example> 
	^ self segment: 1 index: 3
]

{ #category : #'instance creation' }
SOObjectId class >> segment: segmentId index: index [
	^ self new 
		segment: segmentId index: index
]

{ #category : #'as yet unclassified' }
SOObjectId class >> soilRawMaterialize: materializer [ 
	^ self new 
		segment: materializer nextLengthEncodedInteger
		index: materializer nextLengthEncodedInteger 
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
	^ index asByteArrayOfSize: 8
]

{ #category : #comparing }
SOObjectId >> hash [ 
	^ segment hash bitXor: index hash
]

{ #category : #accessing }
SOObjectId >> index [
	^ index
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
SOObjectId >> segment: segmentNo index: segmentIndex [ 
	segment := segmentNo.
	index := segmentIndex 
]

{ #category : #accessing }
SOObjectId >> setIndex: anInteger [ 
	index := anInteger 
]

{ #category : #'as yet unclassified' }
SOObjectId >> soilRawSerialize: serializer [ 
	(index = 0) ifTrue: [ Error signal: 'object id not initialized' ].
	serializer 
		nextPutLengthEncodedInteger: segment;
		nextPutLengthEncodedInteger: index
]
