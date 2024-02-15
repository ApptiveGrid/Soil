Class {
	#name : #SoilUpdateDatabaseVersion,
	#superclass : #SoilTransactionJournalEntry,
	#instVars : [
		'databaseVersion',
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
SoilUpdateDatabaseVersion >> commitIn: soil [ 
	soil databaseVersion: databaseVersion  
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
	^ databaseVersion 
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
		<< databaseVersion asString.
]

{ #category : #'instance creation' }
SoilUpdateDatabaseVersion >> readFrom: aStream [ 
	super readFrom: aStream.
	databaseVersion := aStream nextLengthEncodedInteger. 
	previousVersion := aStream nextLengthEncodedInteger
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> value [ 
	^ databaseVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> version: anInteger [ 
	databaseVersion := anInteger 
]

{ #category : #writing }
SoilUpdateDatabaseVersion >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutLengthEncodedInteger: databaseVersion.
	aStream nextPutLengthEncodedInteger: previousVersion. 
]
