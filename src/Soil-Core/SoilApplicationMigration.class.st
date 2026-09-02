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

{ #category : #accessing }
SoilApplicationMigration >> forceMigration: anObject [

	all := anObject
]

{ #category : #initialization }
SoilApplicationMigration >> initialize [ 
	super initialize.
	all := false
]

{ #category : #API }
SoilApplicationMigration >> migrate [
	self needsMigration ifFalse: [ ^ self ].
	self migrateUpToVersion: self targetVersion
]

{ #category : #API }
SoilApplicationMigration >> migrateUpToVersion: applicationVersion [  
	| txn succeeded |
	"persistentVersion is the version that has been applied already, so the
	first step still to run is the one following it"
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
							self persistentVersion: version ]
						ifFalse: [ txn abort ] ] ]
]

{ #category : #API }
SoilApplicationMigration >> migrateVersion: version transaction: aSoilTransaction [ 
	| pragma |
	pragma := self versionPragmaAt: version.
	^ (pragma arguments second | all) 
		ifTrue: [  
			self perform: pragma method selector with: aSoilTransaction.
			true ]
		ifFalse: [ false ]
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
	^ Pragma 
		allNamed: #applicationVersion:auto:
		in: self class
		sortedByArgument: 1
]
