Class {
	#name : #SoilSegmentFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'segment',
		'mutex'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #testing }
SoilSegmentFile class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilSegmentFile
]

{ #category : #accessing }
SoilSegmentFile >> path [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilSegmentFile >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SoilSegmentFile >> soil [
	^ segment soil
]
