Class {
	#name : #SoilBehaviorRegistryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'registry'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SoilBehaviorRegistryTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'sunit-soil') destroy; initializeFilesystem.
	registry := soil behaviorRegistry
]

{ #category : #running }
SoilBehaviorRegistryTest >> tearDown [ 	
	super tearDown.
	soil ifNotNil: [ 
		soil destroy ]
]

{ #category : #tests }
SoilBehaviorRegistryTest >> testRegisterNewClass [
	registry nameAt: #Object put: SOObjectId example.
	self assert: (registry nameAt: #Object ifAbsent: nil) equals: (SOObjectId example).
]
