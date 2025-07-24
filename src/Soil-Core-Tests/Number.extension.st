Extension { #name : #Number }

{ #category : #'*Soil-Core-Tests' }
Number >> asDummySoilObjectId [
	^ SoilObjectId segment: 1 index: self 
]
