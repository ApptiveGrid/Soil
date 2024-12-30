Class {
	#name : #SoilTransactionalVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilTransactionalVisitor >> transaction [

	^ transaction
]

{ #category : #accessing }
SoilTransactionalVisitor >> transaction: anObject [

	transaction := anObject
]

{ #category : #visiting }
SoilTransactionalVisitor >> visitWithTransaction: aSoil [
	transaction := aSoil newTransaction.
	[ self visit: aSoil ]
		ensure: [ transaction abort ] 
]
