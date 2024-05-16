Extension { #name : 'ReadStream' }

{ #category : '*Soil-Serializer' }
ReadStream >> nextLengthEncodedInteger [
	| value |
	value := self next.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]
