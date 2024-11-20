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
SoilTransactionManager >> abortAll [
	transactions copy do: [ :transaction |
		transaction abort ]
]

{ #category : #'commit/abort' }
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

{ #category : #'commit/abort' }
SoilTransactionManager >> commitAndContinueTransaction: aTransaction [ 	
	aTransaction basicCommit.
	aTransaction hasModifications ifTrue: [ 
		soil checkpoint ].
	aTransaction continue
]

{ #category : #'commit/abort' }
SoilTransactionManager >> commitTransaction: aTransaction [ 	
	| modified |
	aTransaction basicCommit.
	modified := aTransaction hasModifications.
	aTransaction basicAbort.
	self removeTransaction: aTransaction.
	modified ifTrue: [ 
		soil checkpoint ].

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

{ #category : #versions }
SoilTransactionManager >> smallestReadVersion [ 
	"detect the smallest read version currently in use"
	^ transactions
		ifNotEmpty: [ transactions min: #readVersion ]
		ifEmpty: [ nil  ]
]

{ #category : #accessing }
SoilTransactionManager >> soil: aSoil [ 
	soil := aSoil
]
