Extension { #name : #WinPlatform }

{ #category : #'*Soil-File' }
WinPlatform >> flockClass [
	^ SoilWindowsFileLock
]

{ #category : #'*Soil-File' }
WinPlatform >> syncFile: fileHandle [
	"Windows implementation of fsync using FlushFileBuffers API"

	^ (SoilWindowsFileLock flushFileBuffers: fileHandle)
		ifTrue: [ 0 ]
		ifFalse: [
			SoilWindowsFileLock getLastError ]
]
