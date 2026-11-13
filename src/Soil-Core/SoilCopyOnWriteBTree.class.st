Class {
	#name : #SoilCopyOnWriteBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'wrapped',
		'writtenPages'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #adding }
SoilCopyOnWriteBTree >> addDirtyPage: aPage [
	"nothing is written from here, the commit applies the journal to the persistent index.
	What is kept is which pages this transaction wrote to: at commit only those are held
	against the persistent index, see #hasWrittenPagesChangedSince:"
	(writtenPages ifNil: [ writtenPages := IdentitySet new ]) add: aPage
]

{ #category : #testing }
SoilCopyOnWriteBTree >> hasWrittenPagesChangedSince: aVersion [
	"whether a transaction after aVersion wrote to one of the pages I wrote to. A page
	allocated here has no counterpart to compare with"
	writtenPages ifNil: [ ^ false ].
	^ writtenPages anySatisfy: [ :each |
		(self store isCopyAt: each offset) and: [
			((wrapped store pageAt: each offset) isOlderThan: aVersion) not ] ]
]

{ #category : #'instance creation' }
SoilCopyOnWriteBTree >> allocatePage [
	^ wrapped allocatePage 
]

{ #category : #testing }
SoilCopyOnWriteBTree >> isPresentOnDisk [
	^ wrapped isPresentOnDisk
]

{ #category : #'instance creation' }
SoilCopyOnWriteBTree >> newPage [ 
	^ wrapped allocatePage
]

{ #category : #accessing }
SoilCopyOnWriteBTree >> persistentIndex [
	^ wrapped persistentIndex 
]

{ #category : #converting }
SoilCopyOnWriteBTree >> thePersistentInstance [
	^ wrapped
]

{ #category : #accessing }
SoilCopyOnWriteBTree >> wrapped [

	^ wrapped
]

{ #category : #accessing }
SoilCopyOnWriteBTree >> wrapped: anObject [

	wrapped := anObject.
	self store: wrapped store asCopyOnWriteStore 
]
