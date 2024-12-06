"
This is a special subclass for all data pages but the first. See superclass comment for more infos
"
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

{ #category : #initialization }
SoilSkipListDataPage >> initializeInIndex: aSoilSkipList [ 
	keySize := aSoilSkipList keySize.
	valueSize := aSoilSkipList valueSize 
]

{ #category : #initialization }
SoilSkipListDataPage >> latestVersion [
	^ 1 
]

{ #category : #'instance creation' }
SoilSkipListDataPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #accessing }
SoilSkipListDataPage >> validate [
	(version > 1) ifTrue: [ 
		Error signal: 'bogus page version' ].
	(pageSize = 4096) ifFalse: [ 
		Error signal: 'bogus page size' ].
	(offset >= 1) ifFalse: [ 
		Error signal: 'bogus offset' ].	
]

{ #category : #writing }
SoilSkipListDataPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	self writeLevelsOn: aStream.

]
