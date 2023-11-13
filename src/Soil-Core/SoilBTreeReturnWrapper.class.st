"
When inserting in the Btree, we we have to return the old value (if there was any).

But insertItem:for: has to return an index entry in case we do a split, too.

This wrapper contains both: the index entry (if there is one) and the orginal value (if there was one)
"
Class {
	#name : #SoilBTreeReturnWrapper,
	#superclass : #Object,
	#instVars : [
		'indexEntry',
		'returnValue'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeReturnWrapper >> indexEntry [

	^ indexEntry
]

{ #category : #accessing }
SoilBTreeReturnWrapper >> indexEntry: anObject [

	indexEntry := anObject
]

{ #category : #accessing }
SoilBTreeReturnWrapper >> indexEntryNeeded [
	^indexEntry isNotNil
]

{ #category : #accessing }
SoilBTreeReturnWrapper >> returnValue [

	^ returnValue
]

{ #category : #accessing }
SoilBTreeReturnWrapper >> returnValue: anObject [

	returnValue := anObject
]
