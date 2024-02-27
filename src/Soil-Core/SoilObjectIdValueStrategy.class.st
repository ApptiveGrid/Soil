Class {
	#name : #SoilObjectIdValueStrategy,
	#superclass : #SoilIndexValueStrategy,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilObjectIdValueStrategy >> convertValue: aByteArray [ 
	^ aByteArray asSoilObjectId 
]

{ #category : #running }
SoilObjectIdValueStrategy >> restoreItem: anAssociation [ 
	^ anAssociation key -> anAssociation value asSoilObjectId 
]
