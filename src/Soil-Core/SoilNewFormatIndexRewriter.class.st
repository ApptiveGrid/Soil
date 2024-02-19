Class {
	#name : #SoilNewFormatIndexRewriter,
	#superclass : #SoilIndexRewriter,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilNewFormatIndexRewriter >> convertIndex [ 
	index := index as: SoilLegacySkipList.
	index store index: index
]

{ #category : #running }
SoilNewFormatIndexRewriter >> convertItem: item [ 
	^ item
]

{ #category : #running }
SoilNewFormatIndexRewriter >> prepareNewIndex [ 
	"create same index class with same parameters but a temporary path instead"
	| headerPage |
	newIndex := SoilSkipList new 
		path: rewritePath;
		initializeFilesystem.
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
