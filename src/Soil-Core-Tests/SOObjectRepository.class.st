Class {
	#name : #SOObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOObjectRepository >> at: objectid [ 
	| segment |
	segment := self segmentWithId: objectid segment.
	^ segment at: objectid index
]

{ #category : #accessing }
SOObjectRepository >> at: objectId put: bytes [ 
	| position segment |
	segment := self segmentWithId: objectId segment.
	segment at: objectId index putBytes: bytes	
]

{ #category : #accessing }
SOObjectRepository >> segmentWithId: anInteger [ 
	^ SOObjectSegment new 
		id: anInteger;
		objectRepository: self 
]

{ #category : #accessing }
SOObjectRepository >> soil [
	^ soil
]

{ #category : #accessing }
SOObjectRepository >> soil: aSoil [ 
	soil := aSoil 
]
