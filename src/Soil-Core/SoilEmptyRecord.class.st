"
A record that holds no object: its payload is empty. Every object Soil serializes begins with the type code of its class, nil as well, so the serializer does not write such a record. It reads all the same - six zero bytes are a record of version 0 with no previous version, no behavior descriptions, no references, no indexes and an empty payload - and only materializing it fails, which the database level does not do. The application level does, but only when asked to, so without this finding the record goes unnamed until a reader touches the object.

In 62399ede on alpha two objects had such records after their objects file had been written anew, and deleting a flow failed on one of them with 'receiver of between:and: is nil'. What the object was, the record no longer says; that is for a person to find out.
"
Class {
	#name : #SoilEmptyRecord,
	#superclass : #SoilFinding,
	#instVars : [
		'objectId',
		'version',
		'position'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilEmptyRecord class >> of: aSoilPersistentClusterVersion [
	^ self new
		objectId: aSoilPersistentClusterVersion objectId
		version: aSoilPersistentClusterVersion version
		position: aSoilPersistentClusterVersion position;
		yourself
]

{ #category : #accessing }
SoilEmptyRecord >> asDictionary [
	^ super asDictionary
		at: #objectId put: objectId printString;
		at: #version put: version;
		at: #position put: position;
		yourself
]

{ #category : #accessing }
SoilEmptyRecord >> description [
	^ 'the record of ', objectId printString, ' at position ', position printString, ' holds no object: version ', version printString, ' with an empty payload'
]

{ #category : #accessing }
SoilEmptyRecord >> kind [
	^ #emptyRecord
]

{ #category : #accessing }
SoilEmptyRecord >> objectId [
	^ objectId
]

{ #category : #initialization }
SoilEmptyRecord >> objectId: aSoilObjectId version: anInteger position: aPosition [
	objectId := aSoilObjectId.
	version := anInteger.
	position := aPosition
]

{ #category : #accessing }
SoilEmptyRecord >> position [
	^ position
]

{ #category : #accessing }
SoilEmptyRecord >> version [
	^ version
]
