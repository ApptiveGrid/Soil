"
This class implements the SoilIndexDictionary that uses a Lined List as an index.

See the superclass for more informaion about indexed dictionaries

"
Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #materializing }
SoilSkipListDictionary class >> soilMaterialize: anObject [ 
	self halt.
	^ super soilMaterialize: anObject 
]

{ #category : #visiting }
SoilSkipListDictionary >> acceptSoil: aSoilVisitor [
	aSoilVisitor visitSkipListDictionary: self 
]

{ #category : #initialization }
SoilSkipListDictionary >> createIndex [ 
	^ SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
		yourself
]
