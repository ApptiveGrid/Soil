Class {
	#name : #SoilMemoryPageCache,
	#superclass : #SoilPageCache,
	#instVars : [
		'registered'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #initialization }
SoilMemoryPageCache >> initialize [ 
	super initialize.
	registered := false.
]

{ #category : #initialization }
SoilMemoryPageCache >> initializeStore: anObject [ 
	self halt.
]

{ #category : #testing }
SoilMemoryPageCache >> isRegistered [
	^ registered 
]

{ #category : #accessing }
SoilMemoryPageCache >> pageFaultAt: anInteger [ 
	^ (anInteger = 1)
		ifTrue: [ index newHeaderPage ]
		ifFalse: [ index newPage ]
]
