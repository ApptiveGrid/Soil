Class {
	#name : #SOSerializerTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOSerializerTest >> testBasicSerialize [
	| bytes |
	bytes := SoilSerializer serializeToBytes: SOTestClusterRoot new.
	self assert: bytes equals: #[ 1 1 2 ]
]
