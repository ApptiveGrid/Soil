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
SoilIndexManager >> registerIndexedObject: aSoilSkipListDictionary [ 
	| registeredIndex |
	registeredIndex :=  aSoilSkipListDictionary index thePersistentInstance
		path: self path / aSoilSkipListDictionary id, #index;
		initializeFilesystem.
	^ semaphore critical: [  
		indexes 
			at: aSoilSkipListDictionary id
			put: registeredIndex ]
]

{ #category : #accessing }
SoilIndexManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]
