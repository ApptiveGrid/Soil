Class {
	#name : #SOSerializerTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOSerializerTest >> testBasicSerialize [
	| bytes |
	bytes := SoilSerializer serializeToBytes: SOTestClusterRoot new.
	self assert: bytes equals: #[1 17 83 79 84 101 115 116 67 108 117 115 116 101 114 82 111 111 116 2]
]
