Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asSkipListKeyOfSize: anInteger [ 
	^ self asByteArrayOfSize: anInteger 
]

{ #category : #'*Soil-Core' }
ByteArray >> asSoilObjectId [
	 ^ SOObjectId readFrom: self readStream.
]

{ #category : #'*Soil-Core' }
ByteArray >> asSoilObjectProxy [ 
	^ self asSoilObjectId asSoilObjectProxy 
]
