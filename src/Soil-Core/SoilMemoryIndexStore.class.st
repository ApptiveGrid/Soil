Class {
	#name : #SoilMemoryIndexStore,
	#superclass : #SoilPagedIndexStore,
	#category : #'Soil-Core-Index-Common'
}

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

{ #category : #accessing }
SoilMemoryIndexStore >> pageFaultAt: anInteger [ 
	^ (anInteger = 1)
		ifTrue: [ pages at: 1 put: index newHeaderPage ]
		ifFalse: [ pages at: anInteger put: index newPage  ]
]

{ #category : #writing }
SoilMemoryIndexStore >> writeContentsToDisk [
	
]
