Class {
	#name : #SoilMetaSegment,
	#superclass : #SoilObjectSegment,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilMetaSegment >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitMetaSegment: self
]

{ #category : #'as yet unclassified' }
SoilMetaSegment >> identifierIndexPath [
	^ self indexManager path / #identifier , #index
]
