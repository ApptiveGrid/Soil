Class {
	#name : #SoilSkipListPage,
	#superclass : #Object,
	#instVars : [
		'index',
		'dirty',
		'pageSize'
	],
	#classInstVars : [
		'random'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListPage class >> pageCode [ 
	self subclassResponsibility 
]

{ #category : #accessing }
SoilSkipListPage class >> random [
	^ random ifNil: [ 
		random := Random seed: Time microsecondClockValue. ]
]

{ #category : #'instance creation' }
SoilSkipListPage class >> readPageFrom: aStream [
	| pageCode pageClass |
	pageCode := aStream next asInteger.
	pageClass := self allSubclasses detect: [ :class | class pageCode = pageCode ].
	^pageClass new readFrom: aStream.
]

{ #category : #accessing }
SoilSkipListPage >> index [
	^ index
]

{ #category : #accessing }
SoilSkipListPage >> index: anInteger [ 
	index := anInteger
]

{ #category : #writing }
SoilSkipListPage >> indexSize [
	^ 2
]

{ #category : #testing }
SoilSkipListPage >> isDirty [
	^ dirty 
]

{ #category : #testing }
SoilSkipListPage >> isLastPage [
	self shouldBeImplemented.
]

{ #category : #accessing }
SoilSkipListPage >> pageSize [
	^ pageSize
]

{ #category : #accessing }
SoilSkipListPage >> pageSize: anInteger [ 
	pageSize := anInteger 
]

{ #category : #printing }
SoilSkipListPage >> printOn: aStream [ 
	aStream << 'page : #' << index asString
]

{ #category : #writing }
SoilSkipListPage >> readFrom: aStream [ 
	dirty := false.
	"we do not read the pageCode here as it was read already"
	self readIndexFrom: aStream
]

{ #category : #writing }
SoilSkipListPage >> readIndexFrom: aStream [ 
	index := (aStream next: self indexSize) asInteger.

]

{ #category : #writing }
SoilSkipListPage >> writeOn: aStream [ 
	dirty := false.
	aStream
		nextPut: self class pageCode;
		nextPutAll: (index asByteArrayOfSize: self indexSize)
]
