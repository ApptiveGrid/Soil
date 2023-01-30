Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asSkipListKeyOfSize: anInteger [
	^ self asByteArrayOfSize: anInteger
]
