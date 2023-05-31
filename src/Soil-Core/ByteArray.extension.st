Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asSkipListKeyOfSize: anInteger [ 
	"temporary measure changing the byte padding side. Should
	be decided and unified"
	self flag: #todo.
	self size = anInteger ifTrue: [^self].
	^(ByteArray new: anInteger)
		replaceFrom: 1 to: (self size min: anInteger)
		with: self
		startingAt: 1
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
