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
SoilSkipListDictionary >> initialize [ 
	super initialize.
	self createIndexWith: SoilSkipList
]

{ #category : #serializing }
SoilSkipListDictionary >> soilMaterialized: aMaterializer [ 
	super soilMaterialized: aMaterializer.
	index allowDuplicateKeys.
	index wrapped allowDuplicateKeys
]
