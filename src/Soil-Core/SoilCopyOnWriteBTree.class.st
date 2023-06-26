Class {
	#name : #SoilCopyOnWriteBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'wrappedBTree'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilCopyOnWriteBTree >> isRegistered [
	^ wrappedBTree isRegistered
]

{ #category : #converting }
SoilCopyOnWriteBTree >> thePersistentInstance [
	^ wrappedBTree
]

{ #category : #accessing }
SoilCopyOnWriteBTree >> wrappedBTree [

	^ wrappedBTree
]

{ #category : #accessing }
SoilCopyOnWriteBTree >> wrappedBTree: anObject [

	wrappedBTree := anObject.
	self store: wrappedBTree store asCopyOnWriteStore 
]
