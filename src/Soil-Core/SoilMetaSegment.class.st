Class {
	#name : #SoilMetaSegment,
	#superclass : #SoilObjectSegment,
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilMetaSegment >> nameIndexPath [
	^ self indexManager path / #identifier , #index
]
