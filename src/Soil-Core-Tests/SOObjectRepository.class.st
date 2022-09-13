Class {
	#name : #SOObjectRepository,
	#superclass : #Object,
	#instVars : [
		'index',
		'objects',
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
SOObjectRepository >> index: aSOObjectIndexFile [ 
	index := aSOObjectIndexFile 
]

{ #category : #accessing }
SOObjectRepository >> objectAt: anInteger [ 
	| position |
	position := index positionAt: anInteger.
	^ objects atPosition: position
]

{ #category : #accessing }
SOObjectRepository >> objects: aSOObjectFile [ 
	objects := aSOObjectFile 
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

{ #category : #'as yet unclassified' }
SOObjectRepository >> storeNewObject: anObject [ 
	| newIndex position |
	newIndex := index lastObjectIndex + 1.
	position := objects size.
	objects appendBytes: anObject.
	index at: newIndex putPosition: position.
	index lastObjectIndex: newIndex.
	^ newIndex 
]
