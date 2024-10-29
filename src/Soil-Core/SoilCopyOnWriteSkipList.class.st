Class {
	#name : #SoilCopyOnWriteSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'wrapped'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SoilCopyOnWriteSkipList >> addDirtyPage: aPage [ 
	
]

{ #category : #'instance creation' }
SoilCopyOnWriteSkipList >> allocatePage [
	^ wrapped allocatePage 
]

{ #category : #testing }
SoilCopyOnWriteSkipList >> isRegistered [
	^ wrapped isRegistered
]

{ #category : #'instance creation' }
SoilCopyOnWriteSkipList >> newPage [ 
	^ wrapped allocatePage
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
