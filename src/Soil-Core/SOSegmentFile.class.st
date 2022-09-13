Class {
	#name : #SOSegmentFile,
	#superclass : #SOBinaryFile,
	#instVars : [
		'segment'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOSegmentFile >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]
