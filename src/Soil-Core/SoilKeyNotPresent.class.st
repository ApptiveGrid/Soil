"
Signalled by a SoilIndexedCollection when an element cannot be removed because an index does not hold its entry: the element was never added, another element is under its primary key, or a key attribute was changed without #update:, so the entry sits under the old key and the key computed from the element now finds nothing. Nothing has been removed when it is signalled, the collection checks every index before it removes from any.

It is a SoilError of its own, the counterpart of SoilKeyAlreadyPresent, so a caller can catch exactly this case.

indexSelector is the selector of the index that misses the entry, key the key computed from the element, elementId the value of the element's primary attribute, the id the element has outside of Soil.
"
Class {
	#name : #SoilKeyNotPresent,
	#superclass : #SoilError,
	#instVars : [
		'indexSelector',
		'key',
		'elementId'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilKeyNotPresent >> elementId [

	^ elementId
]

{ #category : #accessing }
SoilKeyNotPresent >> elementId: anObject [

	elementId := anObject
]

{ #category : #accessing }
SoilKeyNotPresent >> indexSelector [

	^ indexSelector
]

{ #category : #accessing }
SoilKeyNotPresent >> indexSelector: aSymbol [

	indexSelector := aSymbol
]

{ #category : #accessing }
SoilKeyNotPresent >> key [

	^ key
]

{ #category : #accessing }
SoilKeyNotPresent >> key: aByteArray [

	key := aByteArray
]

{ #category : #accessing }
SoilKeyNotPresent >> messageText [
	^ 'derived index on #' , indexSelector asString , ' holds no entry ' , key printString
		, ' for the element ' , elementId printString
]
