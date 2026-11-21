Class {
	#name : #SoilTransactionManager,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactions',
		'semaphore',
		'gateHolder'
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
	"the gate is tested under the same semaphore that registers the transaction: tested
	before, a transaction could slip in between #closeGate and a drain that has already
	looked at the list"
	semaphore critical: [
		self assertGateOpenFor: 'a new transaction'.
		transactions add: aSoilTransaction ]
]

{ #category : #gate }
SoilTransactionManager >> assertGateOpenFor: aString [
	"signals unless the gate is open or the active process is the one that closed it"
	| holder |
	holder := self gateHolder.
	(holder isNil or: [ holder == Processor activeProcess ]) ifFalse: [
		SoilDatabaseLocked new
			holder: holder;
			signal: 'database is locked for maintenance, ', aString, ' is refused' ]
]

{ #category : #gate }
SoilTransactionManager >> closeGate [
	"Refuse new transactions and commits from every process but the active one, until
	#openGate. Open transactions are left alone: they can still read, but they cannot
	commit any more. Use #lockExclusiveWithin: to wait for them as well."
	semaphore critical: [
		self gateHolder ifNotNil: [ :holder |
			SoilDatabaseLocked new
				holder: holder;
				signal: (holder == Processor activeProcess
					ifTrue: [ 'database is already locked by this process' ]
					ifFalse: [ 'database is already locked by another process' ]) ].
		gateHolder := Processor activeProcess ].
	"a commit that already passed its test is inside the database's critical section;
	the next one to enter sees the closed gate, so waiting for this one is all it takes"
	soil ifNotNil: [
		soil critical: [ ].
		soil emit: 'database locked for maintenance' ]
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

{ #category : #gate }
SoilTransactionManager >> gateDo: aBlock [
	"Run aBlock with the gate closed, and open it again afterwards however aBlock ends.
	The process that holds the gate already may nest: it just runs aBlock."
	self gateHolder == Processor activeProcess ifTrue: [ ^ aBlock value ].
	self closeGate.
	^ [ aBlock value ] ensure: [ self openGate ]
]

{ #category : #gate }
SoilTransactionManager >> gateHolder [
	"the process that closed the gate, nil if it is open. A holder that has died without
	opening the gate would keep everybody out for good, so it counts as not there"
	^ gateHolder ifNotNil: [
		gateHolder isTerminated
			ifTrue: [ gateHolder := nil ]
			ifFalse: [ gateHolder ] ]
]

{ #category : #initialization }
SoilTransactionManager >> initialize [
	super initialize.
	transactions := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion
]

{ #category : #gate }
SoilTransactionManager >> isGateClosed [
	^ self gateHolder notNil
]

{ #category : #gate }
SoilTransactionManager >> lockExclusiveWithin: aDuration [
	"Close the gate and wait until every transaction that was open has ended, so that
	nobody else is in the database. If some are still open after aDuration the gate is
	opened again and SoilDatabaseBusy tells which ones. A transaction of the caller
	counts too: it has to be finished before."
	| deadline |
	self closeGate.
	deadline := DateAndTime now + aDuration.
	[ [ semaphore critical: [ transactions isEmpty ] ] whileFalse: [
		DateAndTime now > deadline ifTrue: [
			SoilDatabaseBusy new
				transactions: (semaphore critical: [ transactions copy ]);
				signal: 'transactions are still open' ].
		(Delay forMilliseconds: 10) wait ] ]
			ifCurtailed: [ self openGate ]
]

{ #category : #'instance creation' }
SoilTransactionManager >> newTransaction: aClass readVersion: version [
	| txn |
	txn := aClass new
		soil: soil;
		readVersion: version;
		start;
		yourself.
	self addTransaction: txn.
	soil notificationHandler transactionCreated: txn.
	^ txn
]

{ #category : #gate }
SoilTransactionManager >> openGate [
	"only the process that closed the gate may open it"
	semaphore critical: [
		self gateHolder == Processor activeProcess ifFalse: [
			^ SoilDatabaseLocked new
				holder: self gateHolder;
				signal: 'only the process that locked the database can unlock it' ].
		gateHolder := nil ].
	soil ifNotNil: [ soil emit: 'database unlocked' ]
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
