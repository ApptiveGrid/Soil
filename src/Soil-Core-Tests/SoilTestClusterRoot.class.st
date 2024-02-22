Class {
	#name : 'SoilTestClusterRoot',
	#superclass : 'Object',
	#instVars : [
		'nested'
	],
	#category : 'Soil-Core-Tests',
	#package : 'Soil-Core-Tests'
}

{ #category : 'accessing' }
SoilTestClusterRoot >> nested [

	^ nested
]

{ #category : 'accessing' }
SoilTestClusterRoot >> nested: aSONestedObject [ 
	nested := aSONestedObject 
]
