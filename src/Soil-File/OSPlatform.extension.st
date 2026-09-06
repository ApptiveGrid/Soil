Extension { #name : #OSPlatform }

{ #category : #'*Soil-File' }
OSPlatform >> fileno: stream [

	^ self 
		ffiCall: #(int fileno("FILE *"void *stream))
		module: LibC
]

{ #category : #'*Soil-File' }
OSPlatform >> flockClass [
	Error signal: 'no support for file locking on this platform'
]

{ #category : #'*Soil-File' }
OSPlatform >> fsync: fd [

	^ self 
		ffiCall: #(int fsync(int fd))
		module: LibC
]

{ #category : #'*Soil-File' }
OSPlatform >> syncFile: fileHandle [
	"POSIX default. Platforms without fsync(2) - Windows - override this."

	^ self fsync: (self fileno: fileHandle)
]
