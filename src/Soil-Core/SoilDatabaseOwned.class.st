"
I am signalled by #lockExclusive when another process owns the database. #owner is what that process wrote into the lock file when it claimed the database, e.g. an endpoint to forward to. It is empty if the owner had not written yet, and it may name a process that is gone: the file lock dies with its process, the contents do not.

#isHeldInThisImage tells a claim of this very image, another database object on the same path, from one of another process. Only the second is somebody to forward to: forwarded, the first would come back here. The first is a database object that was dropped or unregistered without being closed, and a caller treats it as the error it is.
"
Class {
	#name : #SoilDatabaseOwned,
	#superclass : #SoilError,
	#instVars : [
		'owner',
		'heldInThisImage'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseOwned >> heldInThisImage: aBoolean [
	heldInThisImage := aBoolean
]

{ #category : #testing }
SoilDatabaseOwned >> isHeldInThisImage [
	"whether the claim that holds the database is one of this image"
	^ heldInThisImage == true
]

{ #category : #accessing }
SoilDatabaseOwned >> messageText [
	^ messageText ifNil: [
		self isHeldInThisImage
			ifTrue: [ 'database is owned by another claim of this image, as ', owner printString ]
			ifFalse: [ 'database is owned by ', owner printString ] ]
]

{ #category : #accessing }
SoilDatabaseOwned >> owner [
	^ owner
]

{ #category : #accessing }
SoilDatabaseOwned >> owner: aString [
	owner := aString
]
