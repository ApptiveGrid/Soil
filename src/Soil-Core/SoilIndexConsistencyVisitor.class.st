Class {
	#name : #SoilIndexConsistencyVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'soil',
		'seen'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #api }
SoilIndexConsistencyVisitor >> check: aSoil [ 
	soil := aSoil.
	self visit: aSoil
]

{ #category : #initialization }
SoilIndexConsistencyVisitor >> initialize [ 
	super initialize.
	seen := Set new.
]

{ #category : #visiting }
SoilIndexConsistencyVisitor >> visitObjectId: aSoilObjectId [ 
	(seen includes: aSoilObjectId) ifTrue: [ ^ aSoilObjectId ].
	seen add: aSoilObjectId.
	self visit: (soil objectRepository at: aSoilObjectId).
	^ aSoilObjectId 
]

{ #category : #visiting }
SoilIndexConsistencyVisitor >> visitPagedFileIndexStore: aSoilPagedFileIndexStore [ 
	| numberOfPages |
	numberOfPages := aSoilPagedFileIndexStore headerPage lastPageIndex.
	1 to: numberOfPages do: [ :pageIndex | | page |
		page := aSoilPagedFileIndexStore pageAt: pageIndex.
		(page right allSatisfy: #isZero) ifTrue: [ 
			(page index = numberOfPages)  ifFalse: [ self halt ] ] ]
]

{ #category : #visiting }
SoilIndexConsistencyVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self visit: ((soil objectRepository segmentAt: aSoilPersistentClusterVersion  segment) indexAt: indexId)  ].
	^ aSoilPersistentClusterVersion 
]
