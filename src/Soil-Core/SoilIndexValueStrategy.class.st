Class {
	#name : #SoilIndexValueStrategy,
	#superclass : #Object,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilIndexValueStrategy >> convertValue: aByteArray [ 
	^ self subclassResponsibility
]
