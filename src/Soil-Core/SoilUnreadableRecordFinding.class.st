"
A record the index points to that cannot be read (SoilUnreadableRecord). A position at or beyond the size the file had when it was read again is a record that is not there; one inside it is a record that is damaged. There is no repair for either here: which of them it is, and what the object was, is for a person to find out.
"
Class {
	#name : #SoilUnreadableRecordFinding,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'version',
		'position',
		'fileSize',
		'reason'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilUnreadableRecordFinding class >> of: aSoilUnreadableRecord [
	^ self new
		objectId: aSoilUnreadableRecord objectId
		version: aSoilUnreadableRecord version
		position: aSoilUnreadableRecord position
		fileSize: aSoilUnreadableRecord fileSize
		reason: aSoilUnreadableRecord reason asString;
		yourself
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #version put: version;
		at: #position put: position;
		at: #fileSize put: fileSize;
		at: #reason put: reason;
		yourself
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> description [
	^ 'the record of ', objectId printString, ' cannot be read at version ', version printString, ' (position ', position printString, ', file size ', fileSize printString, '): ', reason
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> fileSize [
	^ fileSize
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> kind [
	^ #unreadableRecord
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilUnreadableRecordFinding >> objectId: aSoilObjectId version: aVersion position: aPosition fileSize: aFileSize reason: aString [
	objectId := aSoilObjectId.
	version := aVersion.
	position := aPosition.
	fileSize := aFileSize.
	reason := aString
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> position [
	^ position
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> reason [
	^ reason
]

{ #category : #accessing }
SoilUnreadableRecordFinding >> version [
	^ version
]
