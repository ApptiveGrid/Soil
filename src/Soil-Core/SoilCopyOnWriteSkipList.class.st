Class {
	#name : #SoilCopyOnWriteSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'wrappedSkipList'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #testing }
SoilCopyOnWriteSkipList >> isRegistered [
	^ wrappedSkipList isRegistered
]

{ #category : #'instance creation' }
SoilCopyOnWriteSkipList >> newPage [ 
	^ wrappedSkipList newPage
]

{ #category : #converting }
SoilCopyOnWriteSkipList >> thePersistentInstance [
	^ wrappedSkipList
]

{ #category : #converting }
SoilCopyOnWriteSkipList >> wrappedSkipList [
	^ wrappedSkipList
]

{ #category : #accessing }
SoilCopyOnWriteSkipList >> wrappedSkipList: anObject [

	wrappedSkipList := anObject.
	self store: wrappedSkipList store asCopyOnWriteStore 
]
