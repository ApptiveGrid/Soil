"
I am an owner file that another process always holds. An fcntl lock belongs to a process, so within one image the file system never refuses a claim; I refuse it as it would for a second process, and the owner is read from the file as it would be then.
"
Class {
	#name : #SoilTestForeignFileOwnership,
	#superclass : #SoilFileOwnership,
	#category : #'Soil-Core-Tests'
}

{ #category : #private }
SoilTestForeignFileOwnership >> lockFile [
	path exists ifFalse: [ path ensureCreateFile ].
	stream := SoilLockableStream path: path.
	^ false
]
