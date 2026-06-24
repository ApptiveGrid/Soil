Extension { #name : #LibC }

{ #category : #'*Soil-File' }
LibC >> fsync: fd [
	"Flush all modified data of the given file descriptor to disk (POSIX fsync(2))."

	^ self ffiCall: #(int fsync(int fd))
]

{ #category : #'*Soil-File' }
LibC class >> fsync: fd [
	"Flush all modified data of the given file descriptor to disk (POSIX fsync(2))."

	^ self uniqueInstance fsync: fd
]
