Class {
	#name : #SoilObjectTableTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Serializer-Tests'
}

{ #category : #tests }
SoilObjectTableTest >> testAdd [
	| table |
	table := SoilObjectTable new.
	table add: 'Hello'.
	"we always return the alocated index"
	self assert: (table add: #hello) equals: 2.
	self assert: (table add: #hello) equals: 2.
	table add: 'Hello'.
	self assert: table size equals: 2
]

{ #category : #tests }
SoilObjectTableTest >> testIdentityIndexOf [
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

{ #category : #tests }
SoilObjectTableTest >> testIsEmpty [

	| table |
	table := SoilObjectTable new.
	self assert: table isEmpty.
	table add: 'Hello'.
	self assert: table isEmpty not
]
