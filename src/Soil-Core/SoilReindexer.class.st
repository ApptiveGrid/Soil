Class {
	#name : #SoilReindexer,
	#superclass : #Object,
	#instVars : [
		'force',
		'itemBlock',
		'index',
		'reIndexPath',
		'newIndex',
		'newIndexIterator'
	],
	#category : #'Soil-Core'
}

{ #category : #running }
SoilReindexer >> cleanRemoved [
	"wrap item block with a filter that removes stale values"
	| oldBlock |
	oldBlock := itemBlock.
	itemBlock := [ :item |
		item value isRemoved 
			ifTrue: [ nil ]
			ifFalse: [ oldBlock value: item  ] ] 
]

{ #category : #accessing }
SoilReindexer >> force: aBoolean [ 
	force := aBoolean
]

{ #category : #accessing }
SoilReindexer >> index: anIndex [ 
	index := anIndex.
	reIndexPath := anIndex path, #reindex
]

{ #category : #initialization }
SoilReindexer >> initialize [ 
	super initialize.
	force := false.
	itemBlock := [ :item | item ]
]

{ #category : #accessing }
SoilReindexer >> itemBlock: anObject [

	itemBlock := anObject
]

{ #category : #running }
SoilReindexer >> newIndexIterator [  
	^ newIndexIterator ifNil: [  
		newIndexIterator := newIndex newIterator ] 
]

{ #category : #running }
SoilReindexer >> prepareNewIndex [ 
	"create same index class with same parameters but a temporary path instead"
	newIndex := index class new 
		path: reIndexPath;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: index maxLevel;
		keySize: index keySize;
		valueSize: index valueSize
]

{ #category : #running }
SoilReindexer >> replaceIndex [ 
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
SoilReindexer >> run [ 
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

{ #category : #running }
SoilReindexer >> validatePath [
	"forcing a reindex will remove already existing temporary path"
	force ifTrue: [ reIndexPath deleteIfAbsent: [ ] ].
	"if not being forced it is safer to abort if the temporary path for reindexing exists"
	reIndexPath exists 
		ifTrue: [ Error signal: 'path of index reindexing file already exists.' ].
]
