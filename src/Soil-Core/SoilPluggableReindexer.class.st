Class {
	#name : #SoilPluggableReindexer,
	#superclass : #SoilReIndexer,
	#instVars : [
		'itemBlock',
		'indexBlock'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilPluggableReindexer >> cleanRemoved [
	"wrap item block with a filter that removes stale values"
	| oldBlock |
	oldBlock := itemBlock.
	itemBlock := [ :item |
		item value isRemoved 
			ifTrue: [ nil ]
			ifFalse: [ oldBlock value: item  ] ] 
]

{ #category : #running }
SoilPluggableReindexer >> convertItems [ 
	index newIterator basicAssociationsDo: [ :item |
		(itemBlock value: item) ifNotNil: [ :newItem | 
			self storeItem: newItem ] ]
]

{ #category : #accessing }
SoilPluggableReindexer >> indexBlock: anObject [

	indexBlock := anObject
]

{ #category : #initialization }
SoilPluggableReindexer >> initialize [ 
	super initialize.
	itemBlock := [ :item | item ].
	indexBlock := [ :idx | idx ]
]

{ #category : #accessing }
SoilPluggableReindexer >> itemBlock: anObject [

	itemBlock := anObject
]

{ #category : #running }
SoilPluggableReindexer >> prepareNewIndex [ 
	"create same index class with same parameters but a temporary path instead"
	| indexCopy headerPage |
	indexCopy := index class new 
		path: reIndexPath;
		initializeFilesystem.
	newIndex := indexBlock cull: indexCopy cull: index.
	newIndex hasHeaderPage ifFalse: [  
		headerPage := newIndex 
			initializeHeaderPage;
			maxLevel: index maxLevel;
			keySize: index keySize;
			valueSize: index valueSize;
			headerPage.
		"headerPage
			lastPageIndex: index headerPage lastPageIndex;
			lastFreePageIndex: index headerPage lastFreePageIndex" ]
]

{ #category : #running }
SoilPluggableReindexer >> run [ 
	self validatePath.
	self prepareNewIndex.
	[  
		index newIterator basicAssociationsDo: [ :item |
				
				(itemBlock value: item) ifNotNil: [ :newItem | 
					self newIndexIterator at: newItem key put: newItem value ] ] ]
		ifCurtailed: [ 
			reIndexPath deleteIfAbsent: [].
			Error signal: 'reindexing failed' ].
	self replaceIndex 
]
