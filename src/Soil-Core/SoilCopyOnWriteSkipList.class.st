Class {
	#name : #SoilCopyOnWriteSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'wrapped'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #testing }
SoilCopyOnWriteSkipList >> isRegistered [
	^ wrapped isRegistered
]

{ #category : #'instance creation' }
SoilCopyOnWriteSkipList >> newPage [ 
	^ wrapped newPage
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
