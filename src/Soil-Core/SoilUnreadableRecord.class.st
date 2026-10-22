"
A record that cannot be read: the object, the version it was read at, where it was
looked for and how long the file was -- which tells one that is not there from one that
is there and cannot be read.

Said when a transaction reads an object (SoilTransaction>>#objectWithId:, the read every
proxy goes through) or a visitor reads a record, and that fails with an error that is
not Soil's own -- a read that ran off the end of its file and answered 'receiver of < is
nil', a record whose position does not match, a class that is gone. Whoever reads an
object can then tell a failure of the store from a failure of their own code. Their own
materialization hooks (#soilMaterialized: and the like) run inside the read, so an error
in one of those is said as the store's too. Other reads -- #latestObjectWithId: for
behavior descriptions, the read before a new version is written -- are not covered.

What Soil says itself it keeps saying: a SoilError, and a SoilSerializerError of the
serializer, which lies below the core and so cannot be a SoilError -- a layout that
cannot be migrated, say.
"
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

{ #category : #'instance creation' }
SoilUnreadableRecord class >> objectId: aSoilObjectId version: anInteger in: aSegment reason: anError [
	"the record of aSoilObjectId could not be read at version anInteger from aSegment, and
	anError is what the read said. Position and file size are asked guardedly: the segment
	that could not be read may not answer them either, and nil is an answer too"

	^ self new
		objectId: aSoilObjectId;
		version: anInteger;
		position: ([ aSegment heapPositionAt: aSoilObjectId index ] on: Error do: [ nil ]);
		fileSize: ([ (aSegment instVarNamed: #objectFile) size ] on: Error do: [ nil ]);
		reason: (anError messageText ifNil: [ anError class name ]);
		yourself
]

{ #category : #accessing }
SoilUnreadableRecord >> fileSize [
	"how long the file of the segment was when the record could not be read, nil where
	that could not be asked: a position at or beyond it is a record that is not there,
	and one inside it is a record that is there and could not be read or materialized --
	damaged, or written by code that is not loaded"
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
