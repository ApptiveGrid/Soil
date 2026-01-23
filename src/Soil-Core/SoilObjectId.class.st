"
SoilObjectId is a unique ID for all subgraphs (roots) stored in the database.

Object IDs have two parts: segement and index. 

for now, we fix the segment id to be the 16 upper bits and the index be 48 lower bits, this will be configurable in the future

Segment 0 is use for meta data (e.g SoilBehaviorDescription), while domain objects are in Segment 1.

"
Class {
	#name : #SoilObjectId,
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
SoilObjectId class >> example [
	<sampleInstance>

	^ self segment: 1 index: 3
]

{ #category : #'instance creation' }
SoilObjectId class >> readFrom: stream [ 
	"for now fix the segment id to be the 16 upper bits and the index be 48 lower bits
	If this is changed, please update the optimization in ByteArray>>#isRemoved"
	
	| segment index |
	segment := (stream next: 2) asInteger.
	index := (stream next: 6) asInteger.
	^ self segment: segment index: index
]

{ #category : #'instance creation' }
SoilObjectId class >> root [
	^ RootObjectId ifNil: [ RootObjectId := self new segment: 1; index: 1 ]
]

{ #category : #'instance creation' }
SoilObjectId class >> segment: segmentId index: index [
	(segmentId == 1 and: [ index == 1 ]) ifTrue: [ ^ self root ].
	^ self basicNew
		segment: segmentId index: index
]

{ #category : #comparing }
SoilObjectId >> = anObjectId [ 
	(anObjectId class == self class) ifFalse: [ ^ false ].
	"object ids are generated with zero as index because the allocation of the 
	real index needs to be done on commit time"
	(index == 0) ifTrue: [ ^ self == anObjectId ].
	^ segment = anObjectId segment and: [ 
		index = anObjectId index ]
]

{ #category : #visiting }
SoilObjectId >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitObjectId: self
]

{ #category : #converting }
SoilObjectId >> asByteArray [
	^ (segment asByteArrayOfSize: 2), (index asByteArrayOfSize: 6)
]

{ #category : #converting }
SoilObjectId >> asByteArrayOfSize: anInteger [ 
	(anInteger == 8) ifFalse: [ Error signal: 'for now an objectId is of size 8' ].
	^ self asByteArray 
]

{ #category : #converting }
SoilObjectId >> asObjectIdVersion: anInteger [ 
	^ (self as: SoilVersionedObjectId)
		version: anInteger 
]

{ #category : #converting }
SoilObjectId >> asSoilObjectId [
	^ self 
]

{ #category : #converting }
SoilObjectId >> asSoilObjectProxy [
	^ SoilObjectProxy basicNew 
		objectId: self
]

{ #category : #testing }
SoilObjectId >> hasSameSegment: aSegment andIndex: anIndex [ 
	^ (segment == aSegment) and: [ index == anIndex ]
]

{ #category : #comparing }
SoilObjectId >> hash [ 
	"if an index is 0 we fall back to identityHash in order to
	make two uninitialized objectIds distinct"
	(index == 0) ifTrue: [ ^ self identityHash ].
	^ segment hash bitXor: index hash
]

{ #category : #accessing }
SoilObjectId >> index [
	^ index
]

{ #category : #accessing }
SoilObjectId >> index: anInteger [
	index := anInteger 
]

{ #category : #testing }
SoilObjectId >> isInitialized [
	^ index > 0
]

{ #category : #testing }
SoilObjectId >> isMeta [ 
	^ segment == 0
]

{ #category : #testing }
SoilObjectId >> isObjectId [ 
	^ true
]

{ #category : #testing }
SoilObjectId >> isRemoved [ 
	^ (segment == 0) and: [index == 0]
]

{ #category : #testing }
SoilObjectId >> isSameObjectId: aSOObjectId [ 
	^ aSOObjectId hasSameSegment: segment andIndex: index
]

{ #category : #printing }
SoilObjectId >> printOn: aStream [ 
	aStream << 'ObjectId(' << segment asString << ':' << index asString << ')'
]

{ #category : #accessing }
SoilObjectId >> segment [
	^ segment
]

{ #category : #accessing }
SoilObjectId >> segment: anInteger [ 
	segment := anInteger  
	
]

{ #category : #accessing }
SoilObjectId >> segment: segmentNo index: segmentIndex [ 
	segment := segmentNo.
	index := segmentIndex 
]

{ #category : #accessing }
SoilObjectId >> setIndex: anInteger [ 
	index := anInteger 
]

{ #category : #comparing }
SoilObjectId >> soilSizeInMemory [
	"recursive #sizeInMemory for Soil. 
	Note: only works for some objects, e.g. SoilPersistentClusterVersion"
	^ self sizeInMemory 
		+ segment sizeInMemory 
		+ index sizeInMemory 

]

{ #category : #writing }
SoilObjectId >> writeOn: aStream [ 
	"for now fix the segment id to be the 16 upper bits and the index 
	be 48 lower bits"
	aStream 
		nextPutAll: (segment asByteArrayOfSize: 2);
		nextPutAll: (index asByteArrayOfSize: 6)
]
