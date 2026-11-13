Class {
	#name : #SoilCopyOnWriteSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'wrapped',
		'writtenPages'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SoilCopyOnWriteSkipList >> addDirtyPage: aPage [
	"nothing is written from here, the commit applies the journal to the persistent index.
	What is kept is which pages this transaction wrote to: at commit only those are held
	against the persistent index, see #hasWrittenPagesChangedSince:"
	(writtenPages ifNil: [ writtenPages := IdentitySet new ]) add: aPage
]

{ #category : #testing }
SoilCopyOnWriteSkipList >> hasWrittenPagesChangedSince: aVersion [
	"whether a transaction after aVersion wrote to one of the pages I wrote to. A page
	allocated here has no counterpart to compare with"
	writtenPages ifNil: [ ^ false ].
	^ writtenPages anySatisfy: [ :each |
		(self store isCopyAt: each offset) and: [
			((wrapped store pageAt: each offset) isOlderThan: aVersion) not ] ]
]

{ #category : #testing }
SoilCopyOnWriteSkipList >> isPresentOnDisk [
	^ wrapped isPresentOnDisk
]

{ #category : #accessing }
SoilCopyOnWriteSkipList >> persistentIndex [
	^ wrapped persistentIndex 
]

{ #category : #converting }
SoilCopyOnWriteSkipList >> thePersistentInstance [
	^ wrapped
]

{ #category : #converting }
SoilCopyOnWriteSkipList >> wrapped [
	^ wrapped
]

{ #category : #accessing }
SoilCopyOnWriteSkipList >> wrapped: anObject [

	wrapped := anObject.
	self store: wrapped store asCopyOnWriteStore 
]
