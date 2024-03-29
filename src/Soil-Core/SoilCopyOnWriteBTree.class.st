Class {
	#name : #SoilCopyOnWriteBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'wrapped'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilCopyOnWriteBTree >> isRegistered [
	^ wrapped isRegistered
]

{ #category : #'instance creation' }
SoilCopyOnWriteBTree >> newPage [ 
	^ wrapped newPage
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
