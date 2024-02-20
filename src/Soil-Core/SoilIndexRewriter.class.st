Class {
	#name : #SoilIndexRewriter,
	#superclass : #Object,
	#instVars : [
		'index',
		'force',
		'newIndex',
		'newIndexIterator',
		'rewritePath'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexRewriter class >> index: anIndex [ 
	^ self new 
		index: anIndex 
]

{ #category : #running }
SoilIndexRewriter >> convertIndex [
	self subclassResponsibility 
]

{ #category : #running }
SoilIndexRewriter >> convertItem: item [
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
SoilIndexRewriter >> convertItems [
	index newIterator basicAssociationsDo: [ :item |
		self storeItem: (self convertItem: item) ] 
]

{ #category : #accessing }
SoilIndexRewriter >> force: aBoolean [ 
	force := aBoolean
]

{ #category : #accessing }
SoilIndexRewriter >> index: anIndex [ 
	index := anIndex.
	rewritePath := anIndex path, #reindex
]

{ #category : #initialization }
SoilIndexRewriter >> initialize [ 
	super initialize.
	force := false.

]

{ #category : #running }
SoilIndexRewriter >> newIndexIterator [  
	^ newIndexIterator ifNil: [  
		newIndexIterator := newIndex newIterator ] 
]

{ #category : #running }
SoilIndexRewriter >> replaceIndex [ 
	"flush new index to disk and then close streams"
	newIndex 
		flush;
		close.
	"close old index so the file store gets unloaded"
	index close.
	"replace old index file with new index file"
	index path delete.
	rewritePath moveTo: index path.
	"reopen source index to load new index file"
	index open.
	
]

{ #category : #running }
SoilIndexRewriter >> rewrite [ 
	self validatePath.
	[  
		self 
			convertIndex;
			prepareNewIndex;
			convertItems; 
			replaceIndex  ]
		ifCurtailed: [ 
			rewritePath deleteIfAbsent: [].
			Error signal: 'reindexing failed' ].
]

{ #category : #running }
SoilIndexRewriter >> storeItem: anItem [ 
	self newIndexIterator at: anItem key put: anItem value 
]

{ #category : #running }
SoilIndexRewriter >> validatePath [
	"forcing a reindex will remove already existing temporary path"
	force ifTrue: [ rewritePath deleteIfAbsent: [ ] ].
	"if not being forced it is safer to abort if the temporary path for reindexing exists"
	rewritePath exists 
		ifTrue: [ Error signal: 'path of index reindexing file already exists.' ].
]
