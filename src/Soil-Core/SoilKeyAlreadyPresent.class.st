"
Signalled by a SoilIndexedCollection when an element cannot be added because another element holds its key already: the primary key, or the value of a unique derived index. Nothing has been written when it is signalled.

It is a SoilError of its own, apart from SoilUnsupportedError which stands for a value that cannot be indexed or a collection that is built wrongly, so a caller can catch exactly this case. The other transaction that adds the same key at the same time is not this error, it is the SoilIndexHasConcurrentChange of the commit.

indexSelector is the selector of the index that holds the key, value the value of the added element that is taken, key the key built from it.
"
Class {
	#name : #SoilKeyAlreadyPresent,
	#superclass : #SoilError,
	#instVars : [
		'indexSelector',
		'value',
		'key'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilKeyAlreadyPresent >> indexSelector [

	^ indexSelector
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> indexSelector: aSymbol [

	indexSelector := aSymbol
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> key [

	^ key
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> key: aByteArray [

	key := aByteArray
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> messageText [
	^ 'derived index on #' , indexSelector asString , ': another element has the value ' , value printString , ' already'
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> value [

	^ value
]

{ #category : #accessing }
SoilKeyAlreadyPresent >> value: anObject [

	value := anObject
]
