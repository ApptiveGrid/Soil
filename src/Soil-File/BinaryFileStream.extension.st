Extension { #name : #BinaryFileStream }

{ #category : #'*Soil-File' }
BinaryFileStream >> fileHandle [

	^ handle pointerAt: 9
]

{ #category : #'*Soil-File' }
BinaryFileStream >> flockClass [
	^ OSPlatform current flockClass
]

{ #category : #'*Soil-File' }
BinaryFileStream >> lockAt: position length: length [
	^ self flockClass
		lock: self fileHandle
		from: position
		length: length
]

{ #category : #'*Soil-File' }
BinaryFileStream >> releaseLockAndClose [
	"Close file associatied with receiver."

	self unlock.
	self closed
		ifFalse: [ self close ]
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlock [
	^ self flockClass
		unlock: self fileHandle
		from: 0
		length: self size
]

{ #category : #'*Soil-File' }
BinaryFileStream >> unlockAt: position length: length [

	^ self flockClass
		unlock: self fileHandle
		from: position
		length: length
]
