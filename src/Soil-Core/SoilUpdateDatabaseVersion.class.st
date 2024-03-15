Class {
	#name : #SoilUpdateDatabaseVersion,
	#superclass : #SoilTransactionJournalEntry,
	#instVars : [
		'databaseVersion',
		'previousDatabaseVersion'
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
	soil control databaseVersion: databaseVersion  
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
SoilUpdateDatabaseVersion >> databaseVersion: anInteger [ 
	databaseVersion := anInteger 
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
	^ previousDatabaseVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> previousDatabaseVersion [ 
	^ previousDatabaseVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> previousDatabaseVersion: anInteger [ 
	previousDatabaseVersion := anInteger
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
	previousDatabaseVersion := aStream nextLengthEncodedInteger
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> value [ 
	^ databaseVersion 
]

{ #category : #writing }
SoilUpdateDatabaseVersion >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutLengthEncodedInteger: databaseVersion.
	aStream nextPutLengthEncodedInteger: previousDatabaseVersion. 
]
