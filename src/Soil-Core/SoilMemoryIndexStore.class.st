"
A SoilMemoryIndexStore keeps all pages of an index in memory. It is used for
indexes that do not (yet) have a file behind them, for instance an index that is
built up in a transaction and only gets a file when the transaction commits and
the journal entry creating the index is replayed.

All pages are held in #pages, so a page fault means the page was never allocated.
The header page has to be created explicitly with #initializeHeaderPage.
"
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
	"there is no resource to release"
]

{ #category : #flushing }
SoilMemoryIndexStore >> flush [
	"the pages are the storage, there is nothing to flush them to"
]

{ #category : #flushing }
SoilMemoryIndexStore >> flushPages [
	"the pages are the storage, there is nothing to flush them to"
]

{ #category : #initialization }
SoilMemoryIndexStore >> initializeFilesystem [
	"there is no filesystem behind this store"
]

{ #category : #initialization }
SoilMemoryIndexStore >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pagesMutex critical: [
		pages at: page offset put: page ]
]

{ #category : #testing }
SoilMemoryIndexStore >> isOpen [
	^ true
]

{ #category : #'open/close' }
SoilMemoryIndexStore >> open [
	"a memory store is always open"
]

{ #category : #accessing }
SoilMemoryIndexStore >> pageFaultAt: anInteger [
	"every page of a memory store is allocated through #pageAt:put:, so a page
	that is not in #pages does not exist. A missing header page means the store
	was never initialized with #initializeHeaderPage"
	^ self error: 'memory index store has no page at offset ', anInteger printString
]

{ #category : #writing }
SoilMemoryIndexStore >> writeContentsToDisk [
	"there is no disk behind this store"
]
