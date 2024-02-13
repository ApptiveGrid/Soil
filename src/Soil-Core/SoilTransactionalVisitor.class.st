Class {
	#name : #SoilTransactionalVisitor,
	#superclass : #SoilInstanceVisitor,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #visiting }
SoilTransactionalVisitor >> scan: aSoil [
	soil := aSoil.
	transaction := soil newTransaction.
	[ self visit: aSoil ]
		ensure: [ transaction abort ] 
]

{ #category : #accessing }
SoilTransactionalVisitor >> transaction [

	^ transaction
]

{ #category : #accessing }
SoilTransactionalVisitor >> transaction: anObject [

	transaction := anObject
]
