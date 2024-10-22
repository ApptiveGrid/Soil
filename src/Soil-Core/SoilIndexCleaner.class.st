Class {
	#name : #SoilIndexCleaner,
	#superclass : #Object,
	#instVars : [
		'index',
		'readVersion',
		'dirtyPages'
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
	self dirtyPages do: [ :page |
		"if no transaction needs old state and the page needs cleaning"
		((self canDiscardOldState: page) and: [ page needsCleanup ]) ifTrue: [  
			self cleanPage: page ] ].
	"Now we have a final set if dirty pages"
	index dirtyPages copy do: [ :page | 
		page needsWrite ifTrue: [ 
			index store writePage: page ].
		"pages at this point could still need cleanup"
		page isDirty ifFalse: [ 
			index removeDirtyPage: page ] ].
]

{ #category : #cleaning }
SoilIndexCleaner >> cleanPage: page [
	
	^ page canBeRemoved 
		ifTrue: [ 
			"swap the removed page with its free page counterpart 
			in the dirty list of the index"
			index 
				removeDirtyPage: page;
				addDirtyPage: (index recyclePage: page) ]
		ifFalse: [ 
			"just clean the page"
			page cleanRemoved.
			page ]
]

{ #category : #accessing }
SoilIndexCleaner >> dirtyPages [ 
	^ dirtyPages ifNil: [ 
		dirtyPages := index dirtyPages copy ]
]

{ #category : #accessing }
SoilIndexCleaner >> index: aSoilSkipList [ 
	index := aSoilSkipList
]

{ #category : #accessing }
SoilIndexCleaner >> readVersion: anUndefinedObject [ 
	readVersion := anUndefinedObject
]
