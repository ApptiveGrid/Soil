"
A version of an object, older than the one that is current, that does not materialize with the classes of this image. A reader at an older version would meet it. An old version can fail where the current one does not, because the class has changed since: that is why it is named apart from SoilUnmaterializableCluster.
"
Class {
	#name : #SoilUnmaterializableVersion,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'version',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilUnmaterializableVersion class >> objectId: aSoilObjectId version: anInteger reason: aString [
	^ self new
		objectId: aSoilObjectId version: anInteger reason: aString;
		yourself
]

{ #category : #accessing }
SoilUnmaterializableVersion >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #version put: version;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilUnmaterializableVersion >> description [
	^ 'version ', version printString, ' of ', objectId printString, ' does not materialize: ', reason
]

{ #category : #accessing }
SoilUnmaterializableVersion >> kind [
	^ #unmaterializableVersion
]

{ #category : #accessing }
SoilUnmaterializableVersion >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilUnmaterializableVersion >> objectId: aSoilObjectId version: anInteger reason: aString [
	objectId := aSoilObjectId.
	version := anInteger.
	reason := aString
]

{ #category : #accessing }
SoilUnmaterializableVersion >> reason [
	^ reason
]

{ #category : #accessing }
SoilUnmaterializableVersion >> version [
	^ version
]
