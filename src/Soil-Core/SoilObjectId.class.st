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
	"for now fix the segment id to be the 16 upper bits and the index 
	be 48 lower bits"
	| segment index |
	segment := (stream next: 2) asInteger.
	index := (stream next: 6) asInteger.
	"(index = 0) ifTrue: [ SoilIndexOutOfRange signal: 'index cannot be zero' ]."
	^ self new 
		segment: segment;
		index: index
]

{ #category : #'instance creation' }
SoilObjectId class >> root [
	^ RootObjectId ifNil: [ RootObjectId := self segment: 1 index: 1 ]
]

{ #category : #'instance creation' }
SoilObjectId class >> segment: segmentId index: index [
	^ self new 
		segment: segmentId index: index
]

{ #category : #comparing }
SoilObjectId >> = anObjectId [ 
	(anObjectId class = self class) ifFalse: [ ^ false ].
	"object ids are generated with zero as index because the allocation of the 
	real index needs to be done on commit time"
	(index = 0) ifTrue: [ ^ self == anObjectId ].
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
	(anInteger = 8) ifFalse: [ Error signal: 'for now an objectId is of size 8' ].
	^ self asByteArray 
]

{ #category : #converting }
SoilObjectId >> asSoilObjectId [
	^ self 
]

{ #category : #converting }
SoilObjectId >> asSoilObjectProxy [
	^ SoilObjectProxy new 
		objectId: self
]

{ #category : #testing }
SoilObjectId >> hasSameSegment: aSegment andIndex: anIndex [ 
	^ (segment = aSegment) and: [ index = anIndex ]
]

{ #category : #comparing }
SoilObjectId >> hash [ 
	"if an index is 0 we fall back to identityHash in order to
	make two uninitialized objectIds distinct"
	(index = 0) ifTrue: [ ^ self identityHash ].
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

{ #category : #initialization }
SoilObjectId >> initialize [ 
	super initialize.
	segment := 1
]

{ #category : #testing }
SoilObjectId >> isInitialized [
	^ index > 0
]

{ #category : #testing }
SoilObjectId >> isObjectId [ 
	^ true
]

{ #category : #testing }
SoilObjectId >> isRemoved [ 
	^ (segment = 0) and: [index = 0]
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

{ #category : #writing }
SoilObjectId >> writeOn: aStream [ 
	"for now fix the segment id to be the 16 upper bits and the index 
	be 48 lower bits"
	aStream 
		nextPutAll: (segment asByteArrayOfSize: 2);
		nextPutAll: (index asByteArrayOfSize: 6)
]
