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
SoilIndexManager >> at: anIndexedObject ifAbsent: aBlock [ 
	^ semaphore critical: [  
		indexes 
			at: anIndexedObject id 
			ifAbsentPut: [ 
				self 
					loadIndexWithId: anIndexedObject 
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
SoilIndexManager >> loadIndexWithId: anIndexedObject ifNone: aBlock [
	| path |
	path := self path / anIndexedObject id , #index.
	^ path exists
		ifTrue: [ anIndexedObject loadFrom: path ]
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
