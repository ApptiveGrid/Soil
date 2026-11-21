"
I am signalled when the database is locked for maintenance (#lockExclusive, #maintenanceDo:, #garbageCollect) and somebody else asks for a transaction or a commit. The same goes for locking a database that is already locked, and for unlocking one that another process locked.

A caller that serves requests answers me with a temporary refusal, e.g. 503 with a retry hint over HTTP. #holder is the process that holds the lock.
"
Class {
	#name : #SoilDatabaseLocked,
	#superclass : #SoilError,
	#instVars : [
		'holder'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseLocked >> holder [
	^ holder
]

{ #category : #accessing }
SoilDatabaseLocked >> holder: aProcess [
	holder := aProcess
]
