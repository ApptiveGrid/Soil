Extension { #name : #ZnBufferedReadStream }

{ #category : #'*Soil-File' }
ZnBufferedReadStream >> nextLengthEncodedInteger [
	| value |
	value := self next.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]
