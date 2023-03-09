Class {
	#name : #SoilIndexManager,
	#superclass : #Object,
	#instVars : [
		'soil',
		'segment'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'initialize-release' }
SoilIndexManager >> close [
	
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> createSkipListIndex: aSoilSkipListDictionary [ 
	^ aSoilSkipListDictionary index
		path: segment path / aSoilSkipListDictionary id, #index;
		initializeList
]

{ #category : #initialization }
SoilIndexManager >> initializeFilesystem [
	
]

{ #category : #'instance creation' }
SoilIndexManager >> open [
	
]

{ #category : #accessing }
SoilIndexManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SoilIndexManager >> soil: aSoil [ 
	soil := aSoil
]
