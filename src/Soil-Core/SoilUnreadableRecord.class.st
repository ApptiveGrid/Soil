Class {
	#name : #SoilUnreadableRecord,
	#superclass : #SoilError,
	#instVars : [
		'objectId',
		'version',
		'position',
		'fileSize',
		'reason'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilUnreadableRecord >> fileSize [
	"how long the file of the segment was when the record could not be read, nil where
	that could not be asked: a position at or beyond it is a record that is not there,
	and one inside it is a record that is damaged"
	^ fileSize
]

{ #category : #accessing }
SoilUnreadableRecord >> fileSize: anInteger [
	fileSize := anInteger
]

{ #category : #accessing }
SoilUnreadableRecord >> messageText [
	^ String streamContents: [ :out |
		out
			<< 'the record of ' << objectId printString
			<< ' cannot be read at version ' << version printString
			<< ' (position ' << position printString
			<< ', file size ' << fileSize printString << '): '
			<< reason asString ]
]

{ #category : #accessing }
SoilUnreadableRecord >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilUnreadableRecord >> objectId: aSoilObjectId [
	objectId := aSoilObjectId
]

{ #category : #accessing }
SoilUnreadableRecord >> position [
	"where the index of the segment says the record is, nil where that could not be asked"
	^ position
]

{ #category : #accessing }
SoilUnreadableRecord >> position: anInteger [
	position := anInteger
]

{ #category : #accessing }
SoilUnreadableRecord >> reason [
	^ reason
]

{ #category : #accessing }
SoilUnreadableRecord >> reason: aString [
	reason := aString
]

{ #category : #accessing }
SoilUnreadableRecord >> version [
	^ version
]

{ #category : #accessing }
SoilUnreadableRecord >> version: anInteger [
	version := anInteger
]
