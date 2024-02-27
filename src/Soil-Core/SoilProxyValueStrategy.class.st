Class {
	#name : #SoilProxyValueStrategy,
	#superclass : #SoilIndexValueStrategy,
	#instVars : [
		'objectRepository'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilProxyValueStrategy >> convertValue: aSoilObjectId [ 
	^ self proxyForObjectId: aSoilObjectId
]

{ #category : #accessing }
SoilProxyValueStrategy >> objectRepository: aSoilTransaction [ 
	objectRepository := aSoilTransaction 
]

{ #category : #running }
SoilProxyValueStrategy >> proxyForObjectId: aSoilObjectId [
	^ objectRepository proxyForObjectId: aSoilObjectId 
]
