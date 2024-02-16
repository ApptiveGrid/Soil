Class {
	#name : #SoilIndexConsistencyVisitor,
	#superclass : #SoilInstanceVisitor,
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilIndexConsistencyVisitor >> check: aSoil [ 
	soil := aSoil.
	self visit: aSoil
]

{ #category : #visiting }
SoilIndexConsistencyVisitor >> visitPagedFileIndexStore: aSoilPagedFileIndexStore [ 
	| numberOfPages |
	numberOfPages := aSoilPagedFileIndexStore headerPage lastPageIndex.
	1 to: numberOfPages do: [ :pageIndex | | page |
		page := aSoilPagedFileIndexStore pageAt: pageIndex.
		(page right allSatisfy: #isZero) ifTrue: [ 
			(page index = numberOfPages)  ifFalse: [ Error signal: 'Index consistency check failed ' ] ] ]
]
