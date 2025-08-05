Extension { #name : #Object }

{ #category : #'*Soil-Core' }
Object >> asSoilSignal [ 
	^ SoilSignal on: self 
]

{ #category : #'*Soil-Core' }
Object >> isObjectId [
	^ false
]

{ #category : #'*Soil-Core' }
Object >> isSoilProxy [ 
	^ false
]

{ #category : #'*Soil-Core' }
Object >> soilClusterRootIn: aSOTransaction [ 
	
]

{ #category : #'*Soil-Core' }
Object >> soilEmit [ 
	self asSoilSignal emit
]

{ #category : #'*Soil-Core' }
Object >> soilSizeInMemory [ 
	^ self class allSlots 
		sum: [ :each | (each read: self) soilSizeInMemory ]
]

{ #category : #'*Soil-Core' }
Object >> theNonSoilProxy [
	^ self 
]
