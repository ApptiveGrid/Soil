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
SOSegmentFile >> path [

	^ self subclassResponsibility
]

{ #category : #accessing }
SOSegmentFile >> segment: anSOObjectSegment [

	segment := anSOObjectSegment
]

{ #category : #accessing }
SOSegmentFile >> soil [

	^ segment soil
]
