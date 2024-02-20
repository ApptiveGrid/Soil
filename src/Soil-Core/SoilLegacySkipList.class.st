Class {
	#name : #SoilLegacySkipList,
	#superclass : #SoilSkipList,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilLegacySkipList >> newHeaderPage [
	^ SoilSkipListLegacyHeaderPage new
		index: 1;
		lastPageIndex: 1;
		lastFreePageIndex: 0;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilLegacySkipList >> readPageClassFrom: aStream [
	^ (super readPageClassFrom: aStream) legacyClass 
]
