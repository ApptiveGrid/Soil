"
Raised when a stream handed to SoilGraphImporter was written in a format version this
importer does not know.

Everything after the version field is read by position, so a stream from another version
would not fail on its own - it would be read as if it were this one, and what came out
would look like data. Refusing at the first field is the only place where the difference
is still visible.
"
Class {
	#name : #SoilIncompatibleExportFormat,
	#superclass : #SoilError,
	#instVars : [
		'importerUnderstands',
		'streamSays'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilIncompatibleExportFormat >> importerUnderstands [
	^ importerUnderstands
]

{ #category : #accessing }
SoilIncompatibleExportFormat >> importerUnderstands: anInteger [
	importerUnderstands := anInteger
]

{ #category : #accessing }
SoilIncompatibleExportFormat >> messageText [
	^ messageText ifNil: [
		  messageText := 'the stream says it is export format version '
		                 , streamSays printString
		                 , ', this importer reads version '
		                 , importerUnderstands printString ]
]

{ #category : #accessing }
SoilIncompatibleExportFormat >> streamSays [
	^ streamSays
]

{ #category : #accessing }
SoilIncompatibleExportFormat >> streamSays: anInteger [
	streamSays := anInteger
]
