"
I am the owner lock of a database, kept in a file: a lock on the whole file says that a process owns the database, and the contents say who that is. Soil>>#lockExclusiveAs: claims through me, see Soil>>#ownership.

The lock is an fcntl lock (F_SETLK), and those belong to the process, not to the stream: closing any stream of the owning process on my file ends the claim, the stream I hold included. So I hold my stream for exactly as long as the claim lasts, and I never open the file while another claim of this image holds it. I find such a claim in this image's lock registry (SoilFileLockRegistry) before I open anything - which is why my stream locks in the image as well as in the file, whatever SoilLockableStream class>>#defaultImageLocked says (an embedder may turn it off for everything else) - and claims of this image go one at a time (ClaimMutex): between looking into the registry and registering there, a second claim would open the file, be refused in memory, close the file again and take the first claim's lock with it.

Another kind of ownership answers the same three messages: #claimAs:, #release and #isHeld, and a claim that fails signals SoilDatabaseOwned with the owner.
"
Class {
	#name : #SoilFileOwnership,
	#superclass : #Object,
	#instVars : [
		'path',
		'stream',
		'owner'
	],
	#classVars : [
		'ClaimMutex'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #initialization }
SoilFileOwnership class >> initialize [
	ClaimMutex := Semaphore forMutualExclusion
]

{ #category : #'instance creation' }
SoilFileOwnership class >> path: aFileReference [
	^ self new
		path: aFileReference;
		yourself
]

{ #category : #claiming }
SoilFileOwnership >> claimAs: aString [
	"Claim the database for this process and write aString into the file, so that
	whoever fails to claim it learns who has it - an endpoint to forward to, for
	instance. Fails with SoilDatabaseOwned, carrying what the owner wrote, when another
	process or another claim of this image holds it. Claiming again while holding it
	does nothing."
	| foreignOwner |
	self isHeld ifTrue: [ ^ self ].
	ClaimMutex critical: [
		foreignOwner := self ownerInImage ifNil: [
			self lockFile
				ifTrue: [
					owner := aString.
					nil ]
				ifFalse: [ self readOwnerAndClose ] ] ].
	foreignOwner ifNotNil: [
		^ SoilDatabaseOwned new
			owner: foreignOwner;
			signal ].
	self writeOwner
]

{ #category : #testing }
SoilFileOwnership >> isHeld [
	^ stream notNil
]

{ #category : #private }
SoilFileOwnership >> lockFile [
	"open the file and lock all of it, in this image's registry and in the file system
	(from 0 to 0 is length 0, which fcntl takes as the whole file and beyond). Answers
	false if another process holds it; the stream stays open then, to read who that is"
	path exists ifFalse: [ path ensureCreateFile ].
	stream := (SoilLockableStream path: path) lockInImageAndInFile.
	^ [ stream lockFrom: 0 to: 0 for: self.
	    true ]
		on: SoilAlreadyLocked
		do: [ :error | false ]
]

{ #category : #accessing }
SoilFileOwnership >> owner [
	"what this claim wrote, nil while it holds nothing"
	^ owner
]

{ #category : #private }
SoilFileOwnership >> ownerInImage [
	"what the claim of this image that holds the file wrote, or nil if none holds it.
	Asked before the file is opened, see the class comment"
	| lock |
	lock := (SoilFileLockRegistry forPath: path)
		lockConflictingWith: (SoilRangeLock from: 0 to: 0 context: self)
		ifNone: [ nil ].
	^ lock ifNotNil: [ lock context owner ]
]

{ #category : #accessing }
SoilFileOwnership >> path [
	^ path
]

{ #category : #accessing }
SoilFileOwnership >> path: aFileReference [
	path := aFileReference asFileReference
]

{ #category : #private }
SoilFileOwnership >> readOwnerAndClose [
	"who holds the file, as written there. The owner takes the lock before it writes, so
	an empty file gets a little patience before it is answered as an empty owner. Closing
	the stream afterwards is safe: this process holds no lock on the file that it could
	take"
	| found retries |
	found := ''.
	retries := 3.
	[ retries >= 0 and: [ found isEmpty ] ] whileTrue: [
		50 milliSeconds wait.
		stream position: 0.
		found := stream upToEnd utf8Decoded.
		retries := retries - 1 ].
	stream close.
	stream := nil.
	^ found
]

{ #category : #claiming }
SoilFileOwnership >> release [
	"Give up the claim. The file is emptied, not deleted: deleted, a process that has it
	open already would lock a file nobody else sees any more, while the next one creates
	a new file and locks that, and two would own the database"
	stream ifNil: [ ^ self ].
	[ stream
		truncate: 0;
		flush.
	  stream close ]
		ensure: [
			stream := nil.
			owner := nil ]
]

{ #category : #private }
SoilFileOwnership >> writeOwner [
	stream
		truncate: 0;
		position: 0;
		nextPutAll: owner utf8Encoded;
		flush;
		sync
]
