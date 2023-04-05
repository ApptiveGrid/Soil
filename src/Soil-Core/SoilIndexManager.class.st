Class {
	#name : #SoilIndexManager,
	#superclass : #Object,
	#instVars : [
		'soil',
		'segment',
		'indexes'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilIndexManager >> at: anIndexedObject ifAbsent: aBlock [ 
	indexes ifNil: [ indexes := Dictionary new ].
	^ indexes 
		at: anIndexedObject id 
		ifAbsentPut: [ 
			self 
				loadIndexWithId: anIndexedObject 
				ifNone: [ aBlock value ] ]
	
]

{ #category : #'initialize-release' }
SoilIndexManager >> close [
	
	indexes values do: #close 
]

{ #category : #initialization }
SoilIndexManager >> initialize [ 
	super initialize.
	indexes := Dictionary new
]

{ #category : #initialization }
SoilIndexManager >> initializeFilesystem [
	
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> loadIndexWithId: anIndexedObject ifNone: aBlock [
	| path |
	path := segment path / anIndexedObject id , #index.
	^ path exists
		ifTrue: [ anIndexedObject loadFrom: path ]
		ifFalse: [ aBlock value ]
]

{ #category : #'instance creation' }
SoilIndexManager >> open [
	
]

{ #category : #'as yet unclassified' }
SoilIndexManager >> registerIndexedObject: aSoilSkipListDictionary [ 
	^ aSoilSkipListDictionary index asWritableIndex
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
