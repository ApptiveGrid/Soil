"
A finding about an index, which is found again by the segment it belongs to and its id.
"
Class {
	#name : #SoilIndexFinding,
	#superclass : #SoilFinding,
	#instVars : [
		'segment',
		'indexId'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilIndexFinding >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #indexId put: indexId;
		yourself
]

{ #category : #accessing }
SoilIndexFinding >> indexId [
	^ indexId
]

{ #category : #accessing }
SoilIndexFinding >> indexIn: aSoil [
	^ (aSoil objectRepository segmentAt: segment) indexAt: indexId
]

{ #category : #accessing }
SoilIndexFinding >> segment [
	^ segment
]

{ #category : #initialization }
SoilIndexFinding >> segment: anInteger indexId: anIndexId [
	segment := anInteger.
	indexId := anIndexId
]
