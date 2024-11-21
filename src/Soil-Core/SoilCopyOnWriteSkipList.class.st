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

{ #category : #testing }
SoilCopyOnWriteSkipList >> isRegistered [
	^ wrapped isRegistered
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
