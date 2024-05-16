Extension { #name : 'WriteStream' }

{ #category : '*Soil-Serializer' }
WriteStream >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ self nextPut: anInteger ].
	self nextPut: ((anInteger bitAnd: 127) bitOr: 128).
	self nextPutLengthEncodedInteger: (anInteger bitShift: -7)
]
