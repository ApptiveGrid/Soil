"
Raised when a graph being exported holds something SoilGraphExporter cannot carry.

The export format is narrower than what Soil can store, and the gap is not always
visible from the outside: a structure that reads and writes perfectly well may have no
place in the stream. Saying so by name beats the doesNotUnderstand that the missing
visit method would otherwise produce, somewhere in the middle of the traversal.
"
Class {
	#name : #SoilUnsupportedInExport,
	#superclass : #SoilError,
	#instVars : [
		'structure'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilUnsupportedInExport >> messageText [
	^ messageText ifNil: [
		  messageText := 'a graph export cannot carry a '
		                 , structure class name asString ]
]

{ #category : #accessing }
SoilUnsupportedInExport >> structure [
	^ structure
]

{ #category : #accessing }
SoilUnsupportedInExport >> structure: anObject [
	structure := anObject
]
