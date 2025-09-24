Extension { #name : #Collection }

{ #category : #'*Soil-Core' }
Collection >> soilSizeInMemory [ 
	^ self 
		inject: self sizeInMemory 
		into: [ :sum :each | 
			sum + each soilSizeInMemory ]
]
