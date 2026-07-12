Class {
	#name : #SoilManualTrackingStrategy,
	#superclass : #SoilReadWriteStrategy,
	#category : #'Soil-Core'
}

{ #category : #public }
SoilManualTrackingStrategy >> markDirty: anObject [ 
	transaction addObjectToBeCommited: anObject 
]

{ #category : #strategy }
SoilManualTrackingStrategy >> prepareCommit [ 
	self serializeObjects 
]
