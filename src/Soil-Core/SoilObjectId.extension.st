Extension { #name : #SoilObjectId }

{ #category : #'*Soil-Core' }
SoilObjectId >> asSoilObjectProxy [
	^ SoilObjectProxy basicNew 
		objectId: self
]

{ #category : #'*Soil-Core' }
SoilObjectId >> findReferencesIn: aDatabase [
	^ SoilReferenceFinder new
		soil: aDatabase;
		find: self;
		references 
]
