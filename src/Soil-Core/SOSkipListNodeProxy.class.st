Class {
	#name : #SOSkipListNodeProxy,
	#superclass : #Object,
	#instVars : [
		'pageNumber',
		'pageIndex'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SOSkipListNodeProxy >> pageIndex [

	^ pageIndex
]

{ #category : #accessing }
SOSkipListNodeProxy >> pageIndex: anObject [

	pageIndex := anObject
]

{ #category : #accessing }
SOSkipListNodeProxy >> pageNumber [

	^ pageNumber
]

{ #category : #accessing }
SOSkipListNodeProxy >> pageNumber: anObject [

	pageNumber := anObject
]

{ #category : #accessing }
SOSkipListNodeProxy >> realNodeIn: aSkipList [ 
	^ (aSkipList pageAt: pageNumber) itemAt: pageIndex
]
