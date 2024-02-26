"
The iterator implements all logic related to iteratoring a low level index.

If ""soil"" and ""readVersion"" is set, the iterator restores values using the transaction log, see SoilIndexIterator>>#journalEntriesFor:startingAt:

There are two main clients
- the low level index forwards all methods related to iterating here, not setting the read version
- the SoilIndexedDictionary sets the readVersion (and never uses the index directly)
"
Class {
	#name : #SoilTransactionIndexIterator,
	#superclass : #SoilIndexIterator,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilTransactionIndexIterator class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilTransactionIndexIterator
]

{ #category : #'instance creation' }
SoilTransactionIndexIterator class >> on: aSoilIndex [
	^ self new 
		index: aSoilIndex 
]

{ #category : #private }
SoilTransactionIndexIterator >> convertItem: item [
	"restore a value that has been removed by a later transaction"
	^ item value isRemoved 
		ifTrue: [
			self 
				historicValueAt: item key 
				ifAbsent: [ nil ] ]
		ifFalse: [
			"restore a value that has been overwritten by a later transaction"   
			self 
				historicValueAt: item key 
				ifAbsent: [ item ] ]
]

{ #category : #private }
SoilTransactionIndexIterator >> historicValueAt: key ifAbsent: absentBlock [
 	"a removed value will return ObjectId 0:0"
 	transaction ifNil: [ ^ absentBlock value ].
 	^ (self currentPage isOlderThan: transaction readVersion) 
 		ifTrue: [ 
 			"all modifications to this page have been done before we
 			started the transaction, so the removal is visibile and 
 			value absent"
 			   absentBlock value ] 
 		ifFalse: [
 			"we determine all changes between our transaction and the
 			last one modifying the page. if we get back changes for the
 			key the value of the oldes entry has the value it had before"
 			(self 
 				journalEntriesFor: key 
 				startingAt: self currentPage lastTransaction)
 					ifNotEmpty: [:entries | key -> entries last oldValue ]
 					ifEmpty: absentBlock]
]

{ #category : #private }
SoilTransactionIndexIterator >> journalEntriesFor: key startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId >  transaction readVersion ] whileTrue: [  
		(transaction soil journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class = SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
				(each key = key) ifTrue: [ 
					entries add: each ] ]  ].
		transactionId := transactionId - 1.
	].
   ^ entries
]

{ #category : #accessing }
SoilTransactionIndexIterator >> transaction: aSoilTransaction [ 
	transaction := aSoilTransaction
]

{ #category : #transactions }
SoilTransactionIndexIterator >> updateCurrentTransaction: anInteger [ 
	currentPage lastTransaction: anInteger
]
