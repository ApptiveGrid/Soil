Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asIndexKeyOfSize: anInteger [ 
	^ self asByteArrayOfSize: anInteger 
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
	^ self asInteger isZero
]
