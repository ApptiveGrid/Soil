Class {
	#name : #SoilReIndexer,
	#superclass : #Object,
	#instVars : [
		'index',
		'reIndexPath',
		'force',
		'newIndex',
		'newIndexIterator'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilReIndexer >> convertIndex [
	self subclassResponsibility 
]

{ #category : #running }
SoilReIndexer >> convertItem: item [
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
SoilReIndexer >> convertItems [
	index newIterator basicAssociationsDo: [ :item |
		self storeItem: (self convertItem: item) ] 
]

{ #category : #accessing }
SoilReIndexer >> force: aBoolean [ 
	force := aBoolean
]

{ #category : #accessing }
SoilReIndexer >> index: anIndex [ 
	index := anIndex.
	reIndexPath := anIndex path, #reindex
]

{ #category : #initialization }
SoilReIndexer >> initialize [ 
	super initialize.
	force := false.

]

{ #category : #running }
SoilReIndexer >> newIndexIterator [  
	^ newIndexIterator ifNil: [  
		newIndexIterator := newIndex newIterator ] 
]

{ #category : #running }
SoilReIndexer >> replaceIndex [ 
	"flush new index to disk and then close streams"
	newIndex 
		flush;
		close.
	"close old index so the file store gets unloaded"
	index close.
	"replace old index file with new index file"
	index path delete.
	reIndexPath moveTo: index path.
	"reopen source index to load new index file"
	index open.
	
]

{ #category : #running }
SoilReIndexer >> run [ 
	self validatePath.
	[  
		self 
			convertIndex;
			prepareNewIndex;
			convertItems; 
			replaceIndex  ]
		ifCurtailed: [ 
			reIndexPath deleteIfAbsent: [].
			Error signal: 'reindexing failed' ].
]

{ #category : #running }
SoilReIndexer >> storeItem: anItem [ 
	self newIndexIterator at: anItem key put: anItem value 
]

{ #category : #running }
SoilReIndexer >> validatePath [
	"forcing a reindex will remove already existing temporary path"
	force ifTrue: [ reIndexPath deleteIfAbsent: [ ] ].
	"if not being forced it is safer to abort if the temporary path for reindexing exists"
	reIndexPath exists 
		ifTrue: [ Error signal: 'path of index reindexing file already exists.' ].
]
