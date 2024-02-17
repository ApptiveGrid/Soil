Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asIndexKeyOfSize: anInteger [ 
	^ (self asByteArrayOfSize: anInteger) asInteger
]

{ #category : #'*Soil-Core' }
ByteArray >> asSoilObjectId [
	 ^ SoilObjectId readFrom: self readStream.
]

{ #category : #'*Soil-Core' }
ByteArray >> asSoilObjectProxy [ 
	^ self asSoilObjectId asSoilObjectProxy 
]

{ #category : #'*Soil-Core' }
ByteArray >> isRemoved [
	"First two bytes are the segment ID, for normal objects it is 1, 
	thus checking that first speeds up the check by avoiding #asInteger"
	^ (self at: 2) == 0 and: [self asInteger == 0]
]
