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
	| value |
	value := self proxyForObjectId: aSoilObjectId.
	^ value soilRealObject 
		ifNotNil: [  value ]
		ifNil: [ nil  ]
]

{ #category : #accessing }
SoilProxyValueStrategy >> objectRepository: aSoilTransaction [ 
	objectRepository := aSoilTransaction 
]

{ #category : #running }
SoilProxyValueStrategy >> proxyForObjectId: aSoilObjectId [
	^ objectRepository proxyForObjectId: aSoilObjectId 
]
