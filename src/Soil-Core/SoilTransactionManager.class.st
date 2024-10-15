Class {
	#name : #SoilTransactionManager,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactions',
		'semaphore'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilTransactionManager >> abortTransaction: aTransaction [ 	
	soil ifNotNil: [  
		soil notificationHandler transactionAborted: self ].
	aTransaction basicAbort.
	self removeTransaction: aTransaction 

]

{ #category : #adding }
SoilTransactionManager >> addTransaction: aSoilTransaction [ 
	semaphore critical: [  
		transactions add: aSoilTransaction ]
]

{ #category : #'as yet unclassified' }
SoilTransactionManager >> commitAndContinueTransaction: aTransaction [ 	
	aTransaction basicCommit.
	aTransaction hasRecordsToCommit ifTrue: [ 
		soil checkpoint ].
	aTransaction continue
]

{ #category : #'as yet unclassified' }
SoilTransactionManager >> commitTransaction: aTransaction [ 	
	aTransaction basicCommit.
	aTransaction hasRecordsToCommit ifTrue: [ 
		soil checkpoint ].
	aTransaction basicAbort.
	self removeTransaction: aTransaction 
]

{ #category : #initialization }
SoilTransactionManager >> initialize [ 
	super initialize.
	transactions := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #'instance creation' }
SoilTransactionManager >> newTransaction: aClass readVersion: version [ 
	| txn |
	txn := aClass new 
		soil: soil;
		readVersion: version;
		start;
		yourself.
	soil notificationHandler transactionCreated: txn.
	self addTransaction: txn.
	^ txn
]

{ #category : #removing }
SoilTransactionManager >> removeTransaction: aSoilTransaction [ 
	semaphore critical: [  
		transactions remove: aSoilTransaction ]
]

{ #category : #accessing }
SoilTransactionManager >> soil: aSoil [ 
	soil := aSoil
]
