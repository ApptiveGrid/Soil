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

{ #category : #accessing }
SoilApplicationMigration >> lastVersion [
	^ self availableVersions last
]

{ #category : #API }
SoilApplicationMigration >> migrate [
	self migrateUpToVersion: self lastVersion
]

{ #category : #API }
SoilApplicationMigration >> migrateUpToVersion: applicationVersion [  
	| txn succeeded |
	self persistentVersion to: applicationVersion do: [ :version |
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

{ #category : #accessing }
SoilApplicationMigration >> useAll [
	"migrate all versions even if auto is false"
	all := true
]

{ #category : #accessing }
SoilApplicationMigration >> versionPragmaAt: anInteger [
	^ self versionPragmas 
		detect: [ :each | each arguments first == anInteger ]
]

{ #category : #versions }
SoilApplicationMigration >> versionPragmas [ 
	^ Pragma 
		allNamed: #applicationVersion:auto:
		in: self class
		sortedByArgument: 1
]
