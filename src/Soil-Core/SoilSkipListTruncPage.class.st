Class {
	#name : #SoilSkipListTruncPage,
	#superclass : #SoilSkipListDataPage,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListTruncPage class >> pageCode [ 
	^ 2
]

{ #category : #utilities }
SoilSkipListTruncPage >> headerSize [
	^ self indexSize + (self level * self indexSize)
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
