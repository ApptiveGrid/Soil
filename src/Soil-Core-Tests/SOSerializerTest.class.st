Class {
	#name : #SOSerializerTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOSerializerTest >> testBasicSerialize [
	| serializer bytes |
	serializer := SoilSerializer new.
	bytes := serializer serialize: SOTestClusterRoot new.
	self halt.
]
