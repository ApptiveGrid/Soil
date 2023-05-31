Class {
	#name : #SoilMetaSegment,
	#superclass : #SoilObjectSegment,
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilMetaSegment >> identifierIndexPath [
	^ self indexManager path / #identifier , #index
]
