"
Abstract superclass for all index related pages. Just a place for all shared code.


"
Class {
	#name : #SoilIndexPage,
	#superclass : #Object,
	#instVars : [
		'version',
		'pageSize',
		'offset',
		'needWrite'
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

{ #category : #testing }
SoilIndexPage >> hasRoom [
	^ self subclassResponsibility
]

{ #category : #utilities }
SoilIndexPage >> headerSize [ 
	^ 2 "pageCode, version" 
]

{ #category : #initialization }
SoilIndexPage >> initialize [ 
	super initialize.
	version := self latestVersion
]

{ #category : #testing }
SoilIndexPage >> isDirty [
	^ self subclassResponsibility
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

{ #category : #accessing }
SoilIndexPage >> label [ 
	self subclassResponsibility 
]

{ #category : #initialization }
SoilIndexPage >> latestVersion [
	self subclassResponsibility 
]

{ #category : #accessing }
SoilIndexPage >> markForWrite [
	needWrite := true 
]

{ #category : #testing }
SoilIndexPage >> needsCleanup [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilIndexPage >> needsWrite [
	^ needWrite 
]

{ #category : #accessing }
SoilIndexPage >> offset [
	^ offset
]

{ #category : #accessing }
SoilIndexPage >> offset: anInteger [ 
	offset := anInteger
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
	aStream 
		<< self label 
		<< ' #' 
		<< offset asString
]

{ #category : #reading }
SoilIndexPage >> readFrom: aStream [ 
	needWrite := false.
	"we do not read the pageCode here as it was read already"
	version := aStream next
]

{ #category : #accessing }
SoilIndexPage >> validate [
	(version > 2) ifTrue: [ 
		Error signal: 'bogus page version' ].
	(pageSize = 4096) ifFalse: [ 
		Error signal: 'bogus page size' ]
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
	needWrite := false.
	self writeHeaderOn: aStream
]
