Class {
	#name : 'SoilObjectTable',
	#superclass : 'Object',
	#instVars : [
		'table'
	],
	#category : 'Soil-Serializer-Base',
	#package : 'Soil-Serializer',
	#tag : 'Base'
}

{ #category : 'api' }
SoilObjectTable >> add: anObject [
	table
		at: anObject
		ifAbsentPut: [ table size + 1 ]
]

{ #category : 'api' }
SoilObjectTable >> identityIndexOf: anObject [
	 ^ table at: anObject ifAbsent: 0
]

{ #category : 'initialization' }
SoilObjectTable >> initialize [
	table := IdentityDictionary new
]

{ #category : 'testing' }
SoilObjectTable >> isEmpty [
	^ table isEmpty
]

{ #category : 'accessing' }
SoilObjectTable >> size [
	^ table size
]
