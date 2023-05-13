Class {
	#name : #SoilUpdateDatabaseVersion,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'version'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilUpdateDatabaseVersion class >> journalTypeCode [ 
	^ 5
]

{ #category : #committing }
SoilUpdateDatabaseVersion >> commitIn: aSoilTransaction [ 
	aSoilTransaction soil databaseVersion: version
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> context [
	^ #global
]

{ #category : #'as yet unclassified' }
SoilUpdateDatabaseVersion >> effect [ 
	^ version 
]

{ #category : #printing }
SoilUpdateDatabaseVersion >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' version: '
		<< version asString.
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> version: anInteger [ 
	version := anInteger
]
