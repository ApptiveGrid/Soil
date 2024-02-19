Class {
	#name : #SoilSkipListLegacyDataPage,
	#superclass : #SoilSkipListPage,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListLegacyDataPage class >> pageCode [ 
	^ 2
]

{ #category : #utilities }
SoilSkipListLegacyDataPage >> headerSize [
	^ super headerSize  
		+ 1 "level"
		+ (self level * self rightSize)
		+ 2 "items size"
]

{ #category : #'instance creation' }
SoilSkipListLegacyDataPage >> readFrom: aStream [ 
	dirty := false.
	self 
		readLastTransactionFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #writing }
SoilSkipListLegacyDataPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	self writeLevelsOn: aStream.
	aStream nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).

]
