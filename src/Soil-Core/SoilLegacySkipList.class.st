Class {
	#name : #SoilLegacySkipList,
	#superclass : #SoilSkipList,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilLegacySkipList >> readPageClassFrom: aStream [.
	^ (super readPageClassFrom: aStream) legacyClass 
]
