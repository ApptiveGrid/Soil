Class {
	#name : #SoilIndexManager,
	#superclass : #Object,
	#instVars : [
		'segment',
		'indexes',
		'semaphore'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilIndexManager class >> indexClassFromFile: aFileReference [ 
	| stream pageCode headerPage |
	stream := aFileReference binaryReadStream.
	pageCode := stream next.
	stream close.
	headerPage :={ SoilSkipListHeaderPage . SoilBTreeHeaderPage } detect: [ :each | each pageCode = pageCode ].
	^ headerPage indexClass
]

{ #category : #visiting }
SoilIndexManager >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitIndexManager: self 
]

{ #category : #accessing }
SoilIndexManager >> at: indexId ifAbsent: aBlock [ 
	^ semaphore critical: [  
		indexes 
			at: indexId 
			ifAbsentPut: [ 
				self 
					loadIndexWithId: indexId 
					ifNone: [ aBlock value ] ] ]
		
]

{ #category : #'initialize-release' }
SoilIndexManager >> close [
	semaphore critical: [  
		indexes values do: #close ]
]

{ #category : #initialization }
SoilIndexManager >> initialize [ 
	super initialize.
	indexes := Dictionary new.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilIndexManager >> initializeFilesystem [
	self path ensureCreateDirectory 
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> loadIndexWithId: indexId ifNone: aBlock [
	| path |
	path := self path / indexId , #index.
	^ path exists
		ifTrue: [ 
			(self class indexClassFromFile: path) new 
				path: path;
				open ]
		ifFalse: [ aBlock value ]
]

{ #category : #'instance creation' }
SoilIndexManager >> open [
	
]

{ #category : #accessing }
SoilIndexManager >> path [ 
	^ segment path / #indexes
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> registerIndex: aSoilIndex at: indexId [
	| registeredIndex |
	registeredIndex :=  aSoilIndex thePersistentInstance
		path: self path / indexId , #index;
		initializeFilesystem.
	^ semaphore critical: [  
		indexes 
			at: indexId
			put: registeredIndex ]
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> registerIndexedObject: aSoilIndexObject [ 
	| registeredIndex |
	registeredIndex :=  aSoilIndexObject index thePersistentInstance
		path: self path / aSoilIndexObject id, #index;
		initializeFilesystem.
	^ semaphore critical: [  
		indexes 
			at: aSoilIndexObject id
			put: registeredIndex ]
]

{ #category : #accessing }
SoilIndexManager >> segment [
	^ segment
]

{ #category : #accessing }
SoilIndexManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]
