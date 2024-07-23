Class {
	#name : #SoilBehaviorRegistryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'registry'
	],
	#category : #'Soil-Core-Tests-Model'
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
		soil close ]
]

{ #category : #tests }
SoilBehaviorRegistryTest >> testRegisterNewClass [
	registry nameAt: #Object put: SoilObjectId example.
	self assert: (registry nameAt: #Object ifAbsent: nil) equals: (SoilObjectId example).

]

{ #category : #tests }
SoilBehaviorRegistryTest >> testSOBehaviorDescription [
	"SOBehaviorDescription (the class) itself is always there with index 2"
	self assert: (registry nameAt: #SoilBehaviorDescription ifAbsent: nil) index equals: 2
]
