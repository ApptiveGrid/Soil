Extension { #name : 'ZnBufferedReadWriteStream' }

{ #category : '*Soil-Serializer' }
ZnBufferedReadWriteStream >> nextLengthEncodedInteger [
	| value |
	value := self next.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : '*Soil-Serializer' }
ZnBufferedReadWriteStream >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ self nextPut: anInteger ].
	self nextPut: ((anInteger bitAnd: 127) bitOr: 128).
	self nextPutLengthEncodedInteger: (anInteger bitShift: -7)
]
