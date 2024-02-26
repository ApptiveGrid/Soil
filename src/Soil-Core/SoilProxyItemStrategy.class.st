Class {
	#name : #SoilProxyItemStrategy,
	#superclass : #SoilItemStrategy,
	#instVars : [
		'transaction',
		'iterator'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #running }
SoilProxyItemStrategy >> convertItem: item [ 
	"^ item key -> (transaction proxyForObjectId: item value)"
	"restore a value that has been removed by a later transaction"
	| newItem |
	newItem :=  item value isRemoved 
		ifTrue: [
			self 
				historicValueAt: item key 
				ifAbsent: [ nil ] ]
		ifFalse: [
			"restore a value that has been overwritten by a later transaction"   
			self 
				historicValueAt: item key 
				ifAbsent: [ item ] ].
	^ newItem value 
		ifNotNil: [ item key -> (transaction proxyForObjectId: newItem value) ]
		ifNil: [ newItem ]
]

{ #category : #accessing }
SoilProxyItemStrategy >> historicValueAt: key ifAbsent: absentBlock [
 	"a removed value will return ObjectId 0:0"
 	transaction readVersion ifNil: [ ^ absentBlock value ].
 	^ (iterator currentPage isOlderThan: transaction readVersion) 
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
 				startingAt: iterator currentPage lastTransaction)
 					ifNotEmpty: [:entries | key -> entries last oldValue ]
 					ifEmpty: absentBlock]
]

{ #category : #accessing }
SoilProxyItemStrategy >> iterator: aSoilBTreeIterator [ 
	iterator := aSoilBTreeIterator
]

{ #category : #accessing }
SoilProxyItemStrategy >> journalEntriesFor: key startingAt: anInteger [ 
	| transactionId entries |
	entries := OrderedCollection new.
	transactionId := anInteger.
	[ transactionId > transaction readVersion ] whileTrue: [  
		(transaction soil journal transactionJournalAt: transactionId) entries do: [ :each | 
			((each class = SoilAddKeyEntry) | (each class = SoilRemoveKeyEntry)) ifTrue: [ 
				(each key = key) ifTrue: [ 
					entries add: each ] ]  ].
		transactionId := transactionId - 1.
	].
   ^ entries
]

{ #category : #accessing }
SoilProxyItemStrategy >> transaction: aSoilTransaction [ 
	transaction := aSoilTransaction 
]
