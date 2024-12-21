Class {
	#name : #SoilGarbageCollectVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'newSegment',
		'indexIds',
		'behaviorDescriptions',
		'currentSegment'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'as yet unclassified' }
SoilGarbageCollectVisitor >> cleanIndexes [
	self halt.
]

{ #category : #'as yet unclassified' }
SoilGarbageCollectVisitor >> compactIndexes [

]

{ #category : #'as yet unclassified' }
SoilGarbageCollectVisitor >> garbageCollectHeap [
	currentSegment := soil objectRepository firstSegment.
	newSegment := currentSegment makeGCClone.
	indexIds := Set new.
	behaviorDescriptions := Set new.
	self processObjectId: SoilObjectId root.
	self processLoop.
	newSegment := nil 
]

{ #category : #'as yet unclassified' }
SoilGarbageCollectVisitor >> garbageCollectMeta [
self halt.
	newSegment := soil objectRepository metaSegment makeGCClone.
	toBeProcessed := behaviorDescriptions asOrderedCollection.
	self processLoop.
	newSegment := nil 
]

{ #category : #running }
SoilGarbageCollectVisitor >> run [
	self 
		garbageCollectHeap;
		garbageCollectMeta;
		cleanIndexes;
		compactIndexes
	
]

{ #category : #visiting }
SoilGarbageCollectVisitor >> visitDatabaseJournal: aSoilJournal [ 
	"we ignore the journal for now"
]

{ #category : #visiting }
SoilGarbageCollectVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self halt.
	self processObjectId: SoilObjectId root.
]

{ #category : #visiting }
SoilGarbageCollectVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	newSegment  
		at: aSoilPersistentClusterVersion objectId index
		putBytes: aSoilPersistentClusterVersion serialize.
	aSoilPersistentClusterVersion references do: [ :reference |
		self processObjectId: reference ].
	behaviorDescriptions addAll: aSoilPersistentClusterVersion behaviorDescriptions.
	[aSoilPersistentClusterVersion indexIds do: [ :indexId |
		 self visit: (currentSegment indexManager at: indexId ifAbsent: [ Error signal ]) ] ]
	on: Error do: [:x | ].

	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilGarbageCollectVisitor >> visitSkipList: aSoilSkipList [ 
	| newSkipList |
	indexIds add: aSoilSkipList indexId.
	newSkipList := newSegment indexManager  
		createIndexWithId: aSoilSkipList indexId 
		class: aSoilSkipList class. 
	newSkipList initializeParametersFrom: aSoilSkipList. 
	
	aSoilSkipList newIterator associationsDo: [ :item |
		item value isRemoved ifFalse: [ 
			newSkipList at: item key put: item value.
			self processObjectId: item value asSoilObjectId  ]  ].
	newSkipList close.
]
