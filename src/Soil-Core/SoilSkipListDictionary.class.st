"
This class implements the SoilIndexDictionary that uses a Lined List as an index.

See the superclass for more informaion about indexed dictionaries

"
Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #initialization }
SoilSkipListDictionary >> createIndex [ 
	^ SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
		yourself
]

{ #category : #testing }
SoilSkipListDictionary >> isEmpty [
	^ self newIterator isEmpty
]

{ #category : #serializing }
SoilSkipListDictionary >> soilBasicSerialize: aSerializer [ 
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndexId: id.
]

{ #category : #serializing }
SoilSkipListDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.

]
