"
I am a database whose owner file is always locked by somebody else. An fcntl lock belongs to a process, so within one image a second claim succeeds; I answer as a second process would.
"
Class {
	#name : #SoilTestForeignOwnerDatabase,
	#superclass : #Soil,
	#category : #'Soil-Core-Tests'
}

{ #category : #locking }
SoilTestForeignOwnerDatabase >> acquiredExclusiveLockOn: aStream [
	^ false
]
