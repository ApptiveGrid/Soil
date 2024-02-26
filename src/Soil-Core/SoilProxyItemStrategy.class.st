Class {
	#name : #SoilProxyItemStrategy,
	#superclass : #SoilItemStrategy,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilProxyItemStrategy >> convertItem: item [ 
	^ item key -> (transaction proxyForObjectId: item value)
]

{ #category : #accessing }
SoilProxyItemStrategy >> transaction: aSoilTransaction [ 
	transaction := aSoilTransaction 
]
