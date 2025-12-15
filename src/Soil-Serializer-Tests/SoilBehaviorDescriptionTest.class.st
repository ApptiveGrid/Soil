Class {
	#name : #SoilBehaviorDescriptionTest,
	#superclass : #TestCase,
	#category : #'Soil-Serializer-Tests'
}

{ #category : #tests }
SoilBehaviorDescriptionTest >> testSoilSizeInMemory [
	| instance |
	instance := SoilBehaviorDescription for: Point.
			
	self assert: instance soilSizeInMemory equals: 192
]
