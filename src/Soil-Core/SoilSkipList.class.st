Class {
	#name : #SoilSkipList,
	#superclass : #SoilBasicSkipList,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipList >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitSkipList: self
]

{ #category : #'open/close' }
SoilSkipList >> close [ 
	super close.

]

{ #category : #deleting }
SoilSkipList >> flush [
	self store flush
]

{ #category : #accessing }
SoilSkipList >> indexId [ 
	^ self path withoutExtension basename 
]

{ #category : #initialization }
SoilSkipList >> initializeFilesystem [ 
	self store initializeFilesystem
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self store initializeHeaderPage
]

{ #category : #initialization }
SoilSkipList >> initializeParametersFrom: aSoilSkipList [ 
	self 
		maxLevel: aSoilSkipList maxLevel;
		keySize: aSoilSkipList keySize;
		valueSize: aSoilSkipList valueSize
]

{ #category : #'instance creation' }
SoilSkipList >> newHeaderPage [
	^ SoilSkipListHeaderPage new
		offset: 1;
		lastPageOffset: 1;
		firstFreePageIndex: 0;
		pageSize: self pageSize
]

{ #category : #'opening/closing' }
SoilSkipList >> open [
	self isOpen ifTrue: [ self error: 'Index already open' ].
	self store open
]

{ #category : #serializing }
SoilSkipList >> soilMaterialized: aMaterializer [ 
	store := (aMaterializer indexAt: id) store asCopyOnWriteStore
]

{ #category : #converting }
SoilSkipList >> thePersistentInstance [
	^ self
	
]

{ #category : #writing }
SoilSkipList >> writePages [
	self store flushPages
]
