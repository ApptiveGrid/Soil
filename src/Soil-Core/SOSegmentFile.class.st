Class {
	#name : #SOSegmentFile,
	#superclass : #SOBinaryFile,
	#instVars : [
		'segment'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #testing }
SOSegmentFile class >> isAbstract [
	<ignoreForCoverage>
	^ self == SOSegmentFile
]

{ #category : #accessing }
SOSegmentFile >> close [
	^ self subclassResponsibility
]

{ #category : #accessing }
SOSegmentFile >> path [
	^ self subclassResponsibility
]

{ #category : #accessing }
SOSegmentFile >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment
]
