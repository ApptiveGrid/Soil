Class {
	#name : #SoilPluggableIndexRewriter,
	#superclass : #SoilIndexRewriter,
	#instVars : [
		'itemBlock',
		'indexBlock'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilPluggableIndexRewriter >> cleanRemoved [
	"wrap item block with a filter that removes stale values"
	| oldBlock |
	oldBlock := itemBlock.
	itemBlock := [ :item |
		item value isRemoved 
			ifTrue: [ nil ]
			ifFalse: [ oldBlock value: item  ] ] 
]

{ #category : #running }
SoilPluggableIndexRewriter >> convertIndex [
	
]

{ #category : #running }
SoilPluggableIndexRewriter >> convertItem: item [
	(itemBlock value: item) ifNotNil: [ :newItem | 
		self storeItem: newItem ]
]

{ #category : #running }
SoilPluggableIndexRewriter >> convertItems [ 
	index newIterator basicAssociationsDo: [ :item |
		self convertItem: item ]
]

{ #category : #accessing }
SoilPluggableIndexRewriter >> indexBlock: anObject [

	indexBlock := anObject
]

{ #category : #initialization }
SoilPluggableIndexRewriter >> initialize [ 
	super initialize.
	itemBlock := [ :item | item ].
	indexBlock := [ :idx | idx ]
]

{ #category : #accessing }
SoilPluggableIndexRewriter >> itemBlock: anObject [

	itemBlock := anObject
]

{ #category : #running }
SoilPluggableIndexRewriter >> prepareNewIndex [ 
	"create same index class with same parameters but a temporary path instead"
	| indexCopy headerPage |
	indexCopy := index class new 
		path: rewritePath;
		initializeFilesystem.
	newIndex := indexBlock cull: indexCopy cull: index.
	newIndex hasHeaderPage ifFalse: [  
		headerPage := newIndex 
			initializeHeaderPage;
			maxLevel: index maxLevel;
			keySize: index keySize;
			valueSize: index valueSize;
			headerPage ]
]

{ #category : #running }
SoilPluggableIndexRewriter >> run [ 
	self validatePath.
	self prepareNewIndex.
	[  
		index newIterator basicAssociationsDo: [ :item |
				
				(itemBlock value: item) ifNotNil: [ :newItem | 
					self newIndexIterator at: newItem key put: newItem value ] ] ]
		ifCurtailed: [ 
			rewritePath deleteIfAbsent: [].
			Error signal: 'reindexing failed' ].
	self replaceIndex 
]
