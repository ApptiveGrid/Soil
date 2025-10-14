Class {
	#name : #SoilIndexCleaner,
	#superclass : #Object,
	#instVars : [
		'index',
		'readVersion'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #testing }
SoilIndexCleaner >> canDiscardOldState: aPage [ 
	"if no transaction is in parallel or has a read version old enough
	we can discard removed items from a page"
	^ readVersion isNil or: [ readVersion >= aPage lastTransaction ]
]

{ #category : #cleaning }
SoilIndexCleaner >> clean [ 
	"clean all pages first because the cleaning could produce new pages
	that need to be written"
	index dirtyPages copy do: [ :page |
		"if no transaction needs old state and the page needs cleaning"
		(page needsCleanup and: [ self canDiscardOldState: page ]) ifTrue: [  
			self cleanPage: page ] ].
	"Now we have a final set if dirty pages"
	index dirtyPages copy do: [ :page | 
		page needsWrite ifTrue: [ 
			index writePage: page ].
		"pages at this point could still need cleanup"
		page isDirty ifFalse: [ 
			"index removeDirtyPage: page" ] ].
]

{ #category : #cleaning }
SoilIndexCleaner >> cleanPage: page [
	
	page canBeRemoved 
		ifTrue: [ 
			"swap the removed page with its free page counterpart 
			in the dirty list of the index"
			index 
				removeDirtyPage: page;
				addDirtyPage: (index recyclePage: page) ]
		ifFalse: [ 
			"just clean the page"
			index 
				cleanRemoved: page;
				addDirtyPage: page ]
]

{ #category : #accessing }
SoilIndexCleaner >> index: aSoilSkipList [ 
	index := aSoilSkipList
]

{ #category : #accessing }
SoilIndexCleaner >> readVersion: anUndefinedObject [ 
	readVersion := anUndefinedObject
]
