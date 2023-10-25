Class {
	#name : #SoilLogSequenceNumberTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilLogSequenceNumberTest >> testCreation [ 
	| lsn lsn2 |
	lsn := SoilLogSequenceNumber fileNumber: 16 offset: 32.
	self assert: lsn fileNumber equals: 16.
	self assert: lsn fileOffset equals: 32.
	lsn2 := SoilLogSequenceNumber value: ((16 bitShift: 24) bitOr: 32).
	self assert: lsn2 fileNumber equals: 16.
	self assert: lsn2 fileOffset equals: 32
]

{ #category : #tests }
SoilLogSequenceNumberTest >> testStringValues [
	| lsn |
	lsn := SoilLogSequenceNumber value: ((16 bitShift: 24) bitOr: 32).
	self assert: lsn filename equals: '0000000010'.
	self assert: lsn hexOffset equals: '000020'.

]
