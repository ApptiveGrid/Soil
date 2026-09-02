Class {
	#name : #SoilApplicationMigration,
	#superclass : #Object,
	#instVars : [
		'soil',
		'all'
	],
	#category : #'Soil-Core-Migration'
}

{ #category : #versions }
SoilApplicationMigration >> availableVersions [
	| versions persistentVersion stop |
	stop := false.
	versions := OrderedCollection new.
	persistentVersion := self persistentVersion.
	self versionPragmas do: [ :pragma |
		(pragma arguments second | all) ifFalse: [ stop := true ].
		stop ifFalse: [  
			(pragma arguments first > persistentVersion) ifTrue: [ 
				versions add: pragma ] ] ].
	^ versions collect: [ :pragma | pragma arguments first ]
]

{ #category : #hooks }
SoilApplicationMigration >> didMigrateVersion: version transaction: aSoilTransaction [
	"a version has been applied and the persistent version has been advanced"
	soil metadata updateLastModified
]

{ #category : #accessing }
SoilApplicationMigration >> forceMigration: anObject [

	all := anObject
]

{ #category : #initialization }
SoilApplicationMigration >> initialize [ 
	super initialize.
	all := false
]

{ #category : #logging }
SoilApplicationMigration >> log: aString [
	"where the migration reports what it is doing. Applications that collect
	their log elsewhere override this"
	(SoilSignal on: aString)
		databaseId: soil name;
		emit
]

{ #category : #API }
SoilApplicationMigration >> migrate [
	self needsMigration ifFalse: [ 
		self log: 'application version already at ', self targetVersion printString, ', nothing to migrate'.
		^ self ].
	self log: 'application version ', self persistentVersion printString, ' needs to be migrated to ', self targetVersion printString.
	self migrateUpToVersion: self targetVersion
]

{ #category : #API }
SoilApplicationMigration >> migrateUpToVersion: applicationVersion [  
	| txn succeeded |
	"persistentVersion is the version that has been applied already, so the
	first step still to run is the one following it. Every step runs in a
	transaction of its own and is committed on its own, so a failing step does
	not roll back the steps that already succeeded"
	self persistentVersion + 1 to: applicationVersion do: [ :version |
		succeeded := false.
		txn := soil newTransaction.
		[ 
			(self migrateVersion: version transaction: txn)
				ifTrue: [ succeeded := true ]
				ifFalse: [ ^ self ] ]
				ensure: [ 
					succeeded 
						ifTrue: [ 
							txn commit.
							self persistentVersion: version.
							self didMigrateVersion: version transaction: txn ]
						ifFalse: [ txn abort ] ] ]
]

{ #category : #API }
SoilApplicationMigration >> migrateVersion: version transaction: aSoilTransaction [ 
	| pragma |
	pragma := self versionPragmaAt: version.
	^ (pragma arguments second | all) 
		ifTrue: [  
			self log: 'migrating to application version ', version printString.
			self runMigration: pragma method selector withTransaction: aSoilTransaction.
			true ]
		ifFalse: [ 
			self log: 'stopping before application version ', version printString, ', it is not applied automatically'.
			false ]
]

{ #category : #testing }
SoilApplicationMigration >> needsMigration [
	^ self persistentVersion < self targetVersion
]

{ #category : #versions }
SoilApplicationMigration >> persistentVersion [
	
	^ soil control applicationVersion 
]

{ #category : #versions }
SoilApplicationMigration >> persistentVersion: version [ 
	
	^ soil control applicationVersion: version 
]

{ #category : #API }
SoilApplicationMigration >> runMigration: aSelector withTransaction: aSoilTransaction [
	"the single place a version step is invoked from. Applications that need
	state of their own around a step, e.g. an ambient context built from the
	transaction, override this and call super inside it"
	self perform: aSelector with: aSoilTransaction
]

{ #category : #accessing }
SoilApplicationMigration >> soil: anObject [

	soil := anObject
]

{ #category : #versions }
SoilApplicationMigration >> targetVersion [
	"the version to migrate up to. Defaults to the highest version that can be
	reached through the pragmas. Applications keeping their target version
	elsewhere, e.g. in the code base, override this"
	^ self availableVersions
		ifEmpty: [ self persistentVersion ]
		ifNotEmpty: [ :versions | versions last ]
]

{ #category : #accessing }
SoilApplicationMigration >> useAll [
	"migrate all versions even if auto is false"
	all := true
]

{ #category : #accessing }
SoilApplicationMigration >> versionPragmaAt: anInteger [
	^ self versionPragmas 
		detect: [ :each | each arguments first = anInteger ]
]

{ #category : #versions }
SoilApplicationMigration >> versionPragmas [ 
	"only the methods of this very class are searched, inherited ones are not.
	Version steps therefore have to live in the class that is instantiated,
	subclassing to override a hook does not carry them along"
	^ Pragma 
		allNamed: #applicationVersion:auto:
		in: self class
		sortedByArgument: 1
]
