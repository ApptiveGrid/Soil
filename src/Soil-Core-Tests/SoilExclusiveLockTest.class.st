"
I test claiming a database for one process across processes (#lockExclusive): the lock file says who owns it, and another process that tries is told who that is.
"
Class {
	#name : #SoilExclusiveLockTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilExclusiveLockTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-exclusive-lock-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilExclusiveLockTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilExclusiveLockTest >> testClaimTwiceDoesNothing [
	soil lockExclusiveAs: 'first'.
	soil lockExclusiveAs: 'second'.
	self assert: soil holdsExclusiveLock.
	self assert: soil exclusiveLockFilePath contents equals: 'first'
]

{ #category : #tests }
SoilExclusiveLockTest >> testClaimWritesTheOwner [
	soil lockExclusiveAs: 'image-a:8080'.
	self assert: soil holdsExclusiveLock.
	self assert: soil exclusiveLockFilePath contents equals: 'image-a:8080'
]

{ #category : #tests }
SoilExclusiveLockTest >> testCloseReleasesTheClaim [
	soil lockExclusiveAs: 'image-a:8080'.
	soil close.
	self deny: soil holdsExclusiveLock.
	self assert: soil exclusiveLockFilePath contents isEmpty.
	soil := nil
]

{ #category : #tests }
SoilExclusiveLockTest >> testForeignOwnerIsReported [
	| foreign error |
	soil exclusiveLockFilePath writeStreamDo: [ :stream | stream nextPutAll: 'image-b:8080' ].
	foreign := SoilTestForeignOwnerDatabase new path: soil path.
	error := [ foreign lockExclusive. nil ] on: SoilDatabaseOwned do: [ :e | e ].
	self assert: (error isKindOf: SoilDatabaseOwned).
	self assert: error owner equals: 'image-b:8080'.
	self deny: foreign holdsExclusiveLock
]

{ #category : #tests }
SoilExclusiveLockTest >> testForeignOwnerThatHasNotWrittenYetIsEmpty [
	"the owner holds the lock and has not written who it is: the claim waits a little,
	then reports an empty owner rather than nothing"
	| foreign error |
	soil exclusiveLockFilePath ensureCreateFile.
	foreign := SoilTestForeignOwnerDatabase new path: soil path.
	error := [ foreign lockExclusive. nil ] on: SoilDatabaseOwned do: [ :e | e ].
	self assert: error owner equals: ''
]

{ #category : #tests }
SoilExclusiveLockTest >> testUnlockEmptiesTheFileAndAllowsAClaimAgain [
	"the file stays: deleting it would let two processes own the database"
	soil lockExclusiveAs: 'first'.
	soil unlockExclusive.
	self deny: soil holdsExclusiveLock.
	self assert: soil exclusiveLockFilePath exists.
	self assert: soil exclusiveLockFilePath contents isEmpty.
	soil lockExclusiveAs: 'second'.
	self assert: soil holdsExclusiveLock
]
