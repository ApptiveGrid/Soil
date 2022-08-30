Class {
	#name : #SOObjectManager,
	#superclass : #Object,
	#instVars : [
		'index',
		'objects'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOObjectManager >> index: aSOObjectIndexFile [ 
	index := aSOObjectIndexFile 
]

{ #category : #accessing }
SOObjectManager >> objectAt: anInteger [ 
	| position |
	position := index positionAt: anInteger.
	^ objects atPosition: position
]

{ #category : #accessing }
SOObjectManager >> objects: aSOObjectFile [ 
	objects := aSOObjectFile 
]

{ #category : #'as yet unclassified' }
SOObjectManager >> storeNewObject: anObject [ 
	| newIndex position |
	newIndex := index lastObjectIndex + 1.
	position := objects size.
	objects appendBytes: anObject.
	index at: newIndex putPosition: position.
	index lastObjectIndex: newIndex.
	^ newIndex 
]
