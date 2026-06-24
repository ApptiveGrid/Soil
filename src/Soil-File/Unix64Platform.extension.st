Extension { #name : #Unix64Platform }

{ #category : #'*Soil-File' }
Unix64Platform >> syncFile: fileHandle [
	"Unix/Linux implementation of fsync using the POSIX fsync(2) syscall via the
	existing LibC FFI library. fileHandle is already a usable file descriptor on
	this platform, so call fsync directly rather than going through
	UnixPlatform>>syncFile:'s fileno: lookup"

	^ LibC fsync: fileHandle
]
