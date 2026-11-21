"
I am signalled when locking the database exclusively found transactions that did not end within the time given. The database is not locked then. #transactions are the ones still open.
"
Class {
	#name : #SoilDatabaseBusy,
	#superclass : #SoilError,
	#instVars : [
		'transactions'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseBusy >> transactions [
	^ transactions
]

{ #category : #accessing }
SoilDatabaseBusy >> transactions: aCollection [
	transactions := aCollection
]
