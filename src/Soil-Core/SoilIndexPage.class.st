"
Abstract superclass for all index related pages. Just a place for all shared code.


"
Class {
	#name : #SoilIndexPage,
	#superclass : #Object,
	#instVars : [
		'index',
		'version',
		'dirty',
		'pageSize'
	],
	#classInstVars : [
		'random'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexPage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexPage
]

{ #category : #accessing }
SoilIndexPage class >> pageCode [
	"abstract"
	^ 0 
]

{ #category : #accessing }
SoilIndexPage class >> random [
	^ random ifNil: [ 
		random := Random seed: Time microsecondClockValue. ]
]

{ #category : #'instance creation' }
SoilIndexPage class >> readPageClassFrom: aStream [
	| pageCode |
	pageCode := self readPageCodeFrom: aStream.
	^ self allSubclasses 
		detect: [ :class | class pageCode = pageCode ].
	
]

{ #category : #'instance creation' }
SoilIndexPage class >> readPageCodeFrom: aStream [
	^ aStream next asInteger
	
]

{ #category : #utilities }
SoilIndexPage >> headerSize [ 
	^ 2 "pageCode, version" 
]

{ #category : #accessing }
SoilIndexPage >> index [
	^ index
]

{ #category : #accessing }
SoilIndexPage >> index: anInteger [ 
	index := anInteger
]

{ #category : #initialization }
SoilIndexPage >> initialize [ 
	super initialize.
	version := self latestVersion
]

{ #category : #testing }
SoilIndexPage >> isDirty [
	^ dirty 
]

{ #category : #testing }
SoilIndexPage >> isHeaderPage [
	^ false
]

{ #category : #testing }
SoilIndexPage >> isLastPage [
	self shouldBeImplemented.
]

{ #category : #writing }
SoilIndexPage >> itemsSizeSize [
	"as long as we target 65536 bytes as maximum page size a two-byte 
	number of items is sufficient"
	^ 2
]

{ #category : #initialization }
SoilIndexPage >> latestVersion [
	self subclassResponsibility 
]

{ #category : #accessing }
SoilIndexPage >> markDirty [
	dirty := true 
]

{ #category : #accessing }
SoilIndexPage >> pageSize [
	^ pageSize
]

{ #category : #accessing }
SoilIndexPage >> pageSize: anInteger [ 
	pageSize := anInteger 
]

{ #category : #printing }
SoilIndexPage >> printOn: aStream [ 
	aStream << 'page : #' << index asString
]

{ #category : #reading }
SoilIndexPage >> readFrom: aStream [ 
	dirty := false.
	"we do not read the pageCode here as it was read already"
	version := aStream next
]

{ #category : #accessing }
SoilIndexPage >> version [
	^ version
]

{ #category : #writing }
SoilIndexPage >> writeHeaderOn: aStream [ 
	aStream
		nextPut: self class pageCode;
		nextPut: version
]

{ #category : #writing }
SoilIndexPage >> writeOn: aStream [ 
	dirty := false.
	self writeHeaderOn: aStream
]
