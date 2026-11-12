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

{ #category : #'commit/abort' }
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
	aTransaction needsCommit ifTrue: [ 
		soil checkpoint ].
	aTransaction continue
]

{ #category : #'commit/abort' }
SoilTransactionManager >> commitTransaction: aTransaction [ 	
	| modified |
	aTransaction basicCommit.
	modified := aTransaction needsCommit .
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
	"detect the smallest read version currently in use. The versions are taken under
	the semaphore that guards adding and removing: read without it, the last transaction
	can be removed between the test for emptiness and #min:, which then fails on an
	empty collection"
	| readVersions |
	readVersions := semaphore critical: [
		transactions collect: [ :each | each readVersion ] ].
	^ readVersions
		ifNotEmpty: [ readVersions min ]
		ifEmpty: [ nil ]
]

{ #category : #accessing }
SoilTransactionManager >> soil: aSoil [ 
	soil := aSoil
]
