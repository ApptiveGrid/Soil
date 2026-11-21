"
I am signalled by #lockExclusive when another process owns the database. #owner is what that process wrote into the lock file when it claimed the database, e.g. an endpoint to forward to. It is empty if the owner had not written yet, and it may name a process that is gone: the file lock dies with its process, the contents do not.
"
Class {
	#name : #SoilDatabaseOwned,
	#superclass : #SoilError,
	#instVars : [
		'owner'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseOwned >> messageText [
	^ messageText ifNil: [ 'database is owned by ', owner printString ]
]

{ #category : #accessing }
SoilDatabaseOwned >> owner [
	^ owner
]

{ #category : #accessing }
SoilDatabaseOwned >> owner: aString [
	owner := aString
]
