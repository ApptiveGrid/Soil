Extension { #name : #ZnBufferedReadStream }

{ #category : #'*Soil-File' }
ZnBufferedReadStream >> isOpen [
	"Soil opens journal fragment files that are read back from disk through a
	plain read stream. #isOpen completes the protocol SoilBinaryFile expects."
	^ self closed not
]

{ #category : #'*Soil-File' }
ZnBufferedReadStream >> nextLengthEncodedInteger [
	| value |
	value := self next.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]
