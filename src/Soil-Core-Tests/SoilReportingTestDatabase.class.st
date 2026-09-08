"
A database that collects what it reports instead of signalling it, by filling the
overridable seam Soil>>emit:.

A test can then read the lines straight off it - no logger to start, nothing that
depends on another test having stopped its own, and no dependency on what a
MemoryLogger happens to call its collected signals in this Pharo.
"
Class {
	#name : #SoilReportingTestDatabase,
	#superclass : #Soil,
	#instVars : [
		'reported'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #logging }
SoilReportingTestDatabase >> emit: aString [
	reported add: aString
]

{ #category : #initialization }
SoilReportingTestDatabase >> initialize [
	super initialize.
	reported := OrderedCollection new
]

{ #category : #logging }
SoilReportingTestDatabase >> reported [
	"the lines, in the order they were reported"
	^ reported
]

{ #category : #logging }
SoilReportingTestDatabase >> reportedMatching: aString [
	^ reported select: [ :each | each includesSubstring: aString ]
]
