Extension { #name : #FileReference }

{ #category : #'*Soil-File' }
FileReference >> binaryReadOnlyStream [
	"Answer a buffered binary read-only stream on the receiver. Opening in
	read-only mode avoids requesting write access to a file that may already
	be open for writing, which fails on Windows due to exclusive file locking"

	^ ZnBufferedReadStream on: (filesystem binaryReadStreamOn: self path)
]

{ #category : #'*Soil-File' }
FileReference >> binaryReadWriteStream [
	"Answer a buffered binary write stream on the receiver"

	^ ZnBufferedReadWriteStream on: (filesystem binaryWriteStreamOn: self path)
]
