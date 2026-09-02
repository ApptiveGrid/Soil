Class {
	#name : #SoilResidentError,
	#superclass : #SoilError,
	#instVars : [
		'name'
	],
	#category : #'Soil-Resident'
}

{ #category : #testing }
SoilResidentError class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilResidentError
]

{ #category : #signalling }
SoilResidentError class >> signalForName: aSymbol [
	^ self new
		name: aSymbol;
		signal
]

{ #category : #accessing }
SoilResidentError >> name [
	^ name
]

{ #category : #accessing }
SoilResidentError >> name: aSymbol [
	name := aSymbol
]
