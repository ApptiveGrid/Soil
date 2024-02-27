Class {
	#name : #SoilObjectIdValueStrategy,
	#superclass : #SoilIndexValueStrategy,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilObjectIdValueStrategy >> convertValue: aByteArray [ 
	^ aByteArray asSoilObjectId 
]
