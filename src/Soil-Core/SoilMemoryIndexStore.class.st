Class {
	#name : #SoilMemoryIndexStore,
	#superclass : #SoilPagedIndexStore,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #converting }
SoilMemoryIndexStore >> asCopyOnWriteStore [
	^ SoilCopyOnWriteIndexStore new 
		wrappedStore: self
]

{ #category : #'open/close' }
SoilMemoryIndexStore >> close [
	
]

{ #category : #flushing }
SoilMemoryIndexStore >> flush [ 
	
]

{ #category : #flushing }
SoilMemoryIndexStore >> flushPages [
	
]

{ #category : #initialization }
SoilMemoryIndexStore >> initializeFilesystem [
	
]

{ #category : #initialization }
SoilMemoryIndexStore >> initializeHeaderPage [
	pages at: 1 put: index newHeaderPage 
]

{ #category : #'instance creation' }
SoilMemoryIndexStore >> open [
	
]

{ #category : #accessing }
SoilMemoryIndexStore >> pageFaultAt: anInteger [ 
	^ (anInteger = 1)
		ifTrue: [ pages at: 1 put: index newHeaderPage ]
		ifFalse: [ pages at: anInteger put: index newPage  ]
]

{ #category : #writing }
SoilMemoryIndexStore >> writeContentsToDisk [
	
]
