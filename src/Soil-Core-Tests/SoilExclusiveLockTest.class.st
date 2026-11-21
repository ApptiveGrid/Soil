"
I test claiming a database for one process across processes (#lockExclusive): the lock file says who owns it, and another process that tries is told who that is. Another process is played by SoilTestForeignFileOwnership; another database object of this image on the same path is the real thing.
"
Class {
	#name : #SoilExclusiveLockTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'other'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilExclusiveLockTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-exclusive-lock-tests')
		destroy;
		initializeFilesystem;
		yourself.
	other := Soil new path: soil path
]

{ #category : #running }
SoilExclusiveLockTest >> tearDown [
	super tearDown.
	other unlockExclusive.
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
	foreign := (Soil new path: soil path)
		ownership: (SoilTestForeignFileOwnership path: soil exclusiveLockFilePath);
		yourself.
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
	foreign := (Soil new path: soil path)
		ownership: (SoilTestForeignFileOwnership path: soil exclusiveLockFilePath);
		yourself.
	error := [ foreign lockExclusive. nil ] on: SoilDatabaseOwned do: [ :e | e ].
	self assert: error owner equals: ''
]

{ #category : #tests }
SoilExclusiveLockTest >> testReleaseInThisImageAllowsAnotherClaim [
	soil lockExclusiveAs: 'image-a:8080'.
	soil unlockExclusive.
	other lockExclusiveAs: 'image-a:8081'.
	self assert: other holdsExclusiveLock.
	self assert: soil exclusiveLockFilePath contents equals: 'image-a:8081'
]

{ #category : #tests }
SoilExclusiveLockTest >> testSecondClaimInThisImageIsRefused [
	"the file system would let it through, the lock belongs to the process. The registry
	refuses it before the file is opened: opening and closing it again would end the
	first claim"
	| error |
	soil lockExclusiveAs: 'image-a:8080'.
	error := [ other lockExclusive. nil ] on: SoilDatabaseOwned do: [ :e | e ].
	self assert: error owner equals: 'image-a:8080'.
	self deny: other holdsExclusiveLock.
	self assert: soil holdsExclusiveLock.
	self assert: (SoilFileLockRegistry forPath: soil exclusiveLockFilePath) numberOfLocks equals: 1
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
