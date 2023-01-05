Extension { #name : #BinaryFileStream }

{ #category : #'*Soil-Core' }
BinaryFileStream >> fileHandle [

	^ handle pointerAt: 9
]

{ #category : #'*Soil-Core' }
BinaryFileStream >> flockClass [
	^ OSPlatform current flockClass
]

{ #category : #'*Soil-Core' }
BinaryFileStream >> lockAt: position length: length [
	^ self flockClass
		lock: self fileHandle
		from: position
		to: position + length - 1
]

{ #category : #'*Soil-Core' }
BinaryFileStream >> releaseLockAndClose [
	"Close file associatied with receiver."

	self unlock.
	self closed
		ifFalse: [ self close ]
]

{ #category : #'*Soil-Core' }
BinaryFileStream >> unlock [
	^ self flockClass
		unlock: self fileHandle
		from: 0
		to: self size
]

{ #category : #'*Soil-Core' }
BinaryFileStream >> unlockAt: position length: length [

	^ self flockClass
		unlock: self fileHandle
		from: position
		to: position + length - 1
]
