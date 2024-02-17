"
This is a special subclass for all data pages but the first. See superclass comment for more infos
"
Class {
	#name : #SoilBTreeDataPage,
	#superclass : #SoilAbstractBTreeDataPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeDataPage class >> pageCode [ 
	^ 4
]

{ #category : #utilities }
SoilBTreeDataPage >> headerSize [
	^ super headerSize  
		+ self pointerSize "next"
		+ 2 "items size"
]

{ #category : #reading }
SoilBTreeDataPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self
		readItemsFrom: aStream
]
