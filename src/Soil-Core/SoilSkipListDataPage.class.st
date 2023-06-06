Class {
	#name : #SoilSkipListDataPage,
	#superclass : #SoilSkipListPage,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListDataPage class >> pageCode [ 
	^ 2
]

{ #category : #utilities }
SoilSkipListDataPage >> headerSize [
	^ super headerSize  
		+ 1 "level"
		+ (self level * self rightSize)
]

{ #category : #'instance creation' }
SoilSkipListDataPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #writing }
SoilSkipListDataPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	self writeLevelsOn: aStream
]
