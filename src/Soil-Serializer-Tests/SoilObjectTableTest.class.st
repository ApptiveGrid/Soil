Class {
	#name : #SoilObjectTableTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Serializer-Tests'
}

{ #category : #tests }
SoilObjectTableTest >> testAt [
	| table |
	table := SoilObjectTable new.
	table registerObject: 'Hello'.
	table registerObject: #hello.
	table registerObject: #hello.
	table registerObject: 'Hello'.
	self assert: (table at: 2) equals: #hello.
	self assert: (table at: 1) equals: 'Hello'
]

{ #category : #tests }
SoilObjectTableTest >> testIndexOf [
	| table |
	table := SoilObjectTable new.
	table registerObject: 'Hello'.
	table registerObject: #hello.
	table registerObject: #hello.
	table registerObject: 'Hello'.
	self assert: (table indexOf: #hello) equals: 2.
	self assert: (table indexOf: 'Hello') equals: 1.
	self assert: (table indexOf: '2') equals: 0.
]

{ #category : #tests }
SoilObjectTableTest >> testRegisterObject [
	| table |
	table := SoilObjectTable new.
	table registerObject: 'Hello'.
	table registerObject: #hello.
	table registerObject: #hello.
	table registerObject: 'Hello'.
	self assert: table size equals: 2
]
