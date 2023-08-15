Class {
	#name : #SoilUpdateDatabaseVersion,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'version',
		'previousVersion'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilUpdateDatabaseVersion class >> journalTypeCode [ 
	^ 5
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> address [
	^ #databaseVersion
]

{ #category : #committing }
SoilUpdateDatabaseVersion >> commitIn: aSoilTransaction [ 
	aSoilTransaction soil databaseVersion: version
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> container [
	^ #soil
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> context [
	^ #global
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> effect [ 
	^ version 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> objectIds [
	^ { }
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> oldValue [ 
	^ previousVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> previousVersion [ 
	^ previousVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> previousVersion: anInteger [ 
	previousVersion := anInteger
]

{ #category : #printing }
SoilUpdateDatabaseVersion >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' version: '
		<< version asString.
]

{ #category : #'instance creation' }
SoilUpdateDatabaseVersion >> readFrom: aStream [ 
	super readFrom: aStream.
	version := aStream nextLengthEncodedInteger.
	previousVersion := aStream nextLengthEncodedInteger
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> value [ 
	^ version
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> version: anInteger [ 
	version := anInteger
]

{ #category : #writing }
SoilUpdateDatabaseVersion >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutLengthEncodedInteger: version.
	aStream nextPutLengthEncodedInteger: previousVersion.
]
