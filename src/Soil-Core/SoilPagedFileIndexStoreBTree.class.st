Class {
	#name : #SoilPagedFileIndexStoreBTree,
	#superclass : #SoilPagedFileIndexStore,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #initialization }
SoilPagedFileIndexStoreBTree >> initializeHeaderPage [
	| page |
	super initializeHeaderPage.
	"we create the first index page as the root here"
	page := index newRootPage.
	pagesMutex critical: [  
		pages at: page index put: page	].
	
]
