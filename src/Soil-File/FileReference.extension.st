Extension { #name : #FileReference }

{ #category : #'*Soil-File' }
FileReference >> binaryReadWriteStream [
	"Answer a buffered binary write stream on the receiver"

	^ ZnBufferedReadWriteStream on: (filesystem binaryWriteStreamOn: self path)
]
