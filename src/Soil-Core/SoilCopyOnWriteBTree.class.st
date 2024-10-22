Class {
	#name : #SoilCopyOnWriteBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'wrapped'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilCopyOnWriteBTree >> allocatePage [
	^ self newPage
]

{ #category : #testing }
SoilCopyOnWriteBTree >> isRegistered [
	^ wrapped isRegistered
]

{ #category : #'instance creation' }
SoilCopyOnWriteBTree >> newPage [ 
	^ wrapped allocatePage
]

{ #category : #'as yet unclassified' }
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
