Class {
	#name : #SoilObjectTableTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : 'Soil-Serializer-Tests'
}

{ #category : #tests }
SoilObjectTableTest >> testAdd [
	| table |
	table := SoilObjectTable new.
	table add: 'Hello'.
	table add: #hello.
	table add: #hello.
	table add: 'Hello'.
	self assert: table size equals: 2
]

{ #category : #tests }
SoilObjectTableTest >> testIdenityIndexOf [
	| table |
	table := SoilObjectTable new.
	table add: 'Hello'.
	table add: #hello.
	table add: #hello.
	table add: 'Hello'.
	self assert: (table identityIndexOf: #hello) equals: 2.
	self assert: (table identityIndexOf: 'Hello') equals: 1.
	self assert: (table identityIndexOf: '2') equals: 0.
]
