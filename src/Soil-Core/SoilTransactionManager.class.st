Class {
	#name : #SoilTransactionManager,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilTransactionManager >> newTransaction: aClass readVersion: version [ 
	| txn |
	txn := aClass new 
		soil: soil;
		readVersion: version;
		start;
		yourself.
	soil notificationHandler transactionCreated: txn.
	^ txn
]

{ #category : #accessing }
SoilTransactionManager >> soil: aSoil [ 
	soil := aSoil
]
