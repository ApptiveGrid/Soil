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
SoilIndexCleaner >> canBeModified: aPage [ 
	^ readVersion isNil or: [ readVersion >= aPage lastTransaction ]
]

{ #category : #cleaning }
SoilIndexCleaner >> clean [ 
	index dirtyPages do: [ :p | | page |
		page := p.
		(self canBeModified: page) ifTrue: [  
			page := self cleanPage: page ] ].
	index dirtyPages copy do: [ :page | 
		page needsWrite ifTrue: [ 
			index store writePage: page ].
		page isDirty ifFalse: [ 
				index removeDirtyPage: page ] ].
]

{ #category : #cleaning }
SoilIndexCleaner >> cleanPage: aPage [
	| page |
	page := aPage.
	page needsCleanup ifTrue: [
		^ page canBeRemoved 
			ifTrue: [ 
				index removeDirtyPage: page.
				index addDirtyPage: (index recyclePage: page) ]
			ifFalse: [ page cleanRemoved ] ].
	^ aPage
]

{ #category : #accessing }
SoilIndexCleaner >> index: aSoilSkipList [ 
	index := aSoilSkipList
]

{ #category : #accessing }
SoilIndexCleaner >> readVersion: anUndefinedObject [ 
	readVersion := anUndefinedObject
]
