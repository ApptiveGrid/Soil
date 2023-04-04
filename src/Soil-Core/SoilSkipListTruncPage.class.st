Class {
	#name : #SoilSkipListTruncPage,
	#superclass : #SoilSkipListDataPage,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SoilSkipListTruncPage class >> pageCode [ 
	^ 1
]

{ #category : #utilities }
SoilSkipListTruncPage >> headerSize [
	^ self indexSize + (maxLevel * self indexSize)
]

{ #category : #'instance creation' }
SoilSkipListTruncPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #writing }
SoilSkipListTruncPage >> writeOn: aStream [ 
	super writeOn: aStream.
	self 
		writeLevelsOn: aStream;
		writeItemsOn: aStream
	
]
