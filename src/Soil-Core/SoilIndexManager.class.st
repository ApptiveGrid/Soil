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

{ #category : #initialization }
SoilIndexManager >> initializeFilesystem [
	
]

{ #category : #'instance creation' }
SoilIndexManager >> open [
	
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> registerIndexedObject: aSoilSkipListDictionary [ 
	^ aSoilSkipListDictionary index
		path: segment path / aSoilSkipListDictionary id, #index;
		initializeFilesystem
]

{ #category : #accessing }
SoilIndexManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SoilIndexManager >> soil: aSoil [ 
	soil := aSoil
]
