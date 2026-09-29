"
A cluster that does not materialize with the classes of this image.
"
Class {
	#name : #SoilUnmaterializableCluster,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilUnmaterializableCluster class >> objectId: aSoilObjectId reason: aString [
	^ self new
		objectId: aSoilObjectId reason: aString;
		yourself
]

{ #category : #accessing }
SoilUnmaterializableCluster >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilUnmaterializableCluster >> description [
	^ 'cluster ', objectId printString, ' does not materialize: ', reason
]

{ #category : #accessing }
SoilUnmaterializableCluster >> kind [
	^ #unmaterializableCluster
]

{ #category : #accessing }
SoilUnmaterializableCluster >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilUnmaterializableCluster >> objectId: aSoilObjectId reason: aString [
	objectId := aSoilObjectId.
	reason := aString
]

{ #category : #accessing }
SoilUnmaterializableCluster >> reason [
	^ reason
]
