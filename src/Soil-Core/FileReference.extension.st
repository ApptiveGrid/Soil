Extension { #name : #FileReference }

{ #category : #'*Soil-Core' }
FileReference >> binaryReadWriteStream [
	"Answer a buffered binary write stream on the receiver"

	^ ZnBufferedReadWriteStream on: (filesystem binaryWriteStreamOn: self path)
]
