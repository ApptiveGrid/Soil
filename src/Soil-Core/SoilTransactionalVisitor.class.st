Class {
	#name : #SoilTransactionalVisitor,
	#superclass : #SoilInstanceVisitor,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilTransactionalVisitor >> transaction [

	^ transaction
]

{ #category : #accessing }
SoilTransactionalVisitor >> transaction: anObject [

	transaction := anObject
]
