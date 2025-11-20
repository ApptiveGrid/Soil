Extension { #name : #MacOSXPlatform }

{ #category : #'*Soil-File' }
MacOSXPlatform >> fileno: stream [

	^ self 
		ffiCall: #(int fileno("FILE *"void *stream))
		module: LibC
]

{ #category : #'*Soil-File' }
MacOSXPlatform >> fsync: fd [
	^ self 
		ffiCall: #(int fsync(int fd))
		module: LibC
]

{ #category : #'*Soil-File' }
MacOSXPlatform >> syncFile: fileHandle [
	"Unix/Linux/MacOS implementation of fsync using POSIX API"

	^ self fsync: (self fileno: fileHandle)
]
