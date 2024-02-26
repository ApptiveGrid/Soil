Class {
	#name : #SoilObjectIdItemStrategy,
	#superclass : #SoilItemStrategy,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilObjectIdItemStrategy >> convertItem: anAssociation [ 
	^ anAssociation key -> anAssociation value asSoilObjectId 
]
