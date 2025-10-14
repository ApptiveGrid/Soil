Class {
	#name : #SoilPseudoTransaction,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #api }
SoilPseudoTransaction >> behaviorDescriptionWithObjectId: objectId andVersion: version [ 
	^ soil behaviorRegistry 
		behaviorDescriptionWithIndex: objectId index andVersion: version transaction: self
]

{ #category : #'instance creation' }
SoilPseudoTransaction >> newMaterializer [
	^ soil newMaterializer 
]

{ #category : #accessing }
SoilPseudoTransaction >> segmentAt: anInteger [ 
	^ soil objectRepository segmentAt: anInteger 
]

{ #category : #accessing }
SoilPseudoTransaction >> soil: aSoil [ 
	soil := aSoil
]
