Class {
	#name : #SoilApplicationMigration,
	#superclass : #Object,
	#instVars : [
		'forceUpgrade'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilApplicationMigration >> forceUpgrade: anObject [

	forceUpgrade := anObject
]

{ #category : #initialization }
SoilApplicationMigration >> initialize [ 
	super initialize.
	forceUpgrade := false
]

{ #category : #'as yet unclassified' }
SoilApplicationMigration >> upgrade: version transaction: aSoilTransaction [ 
	| pragma |
	pragma := self versionPragmaAt: version.
	^ (pragma arguments second | forceUpgrade) 
		ifTrue: [  
			self perform: pragma method selector with: aSoilTransaction.
			true ]
		ifFalse: [ false ]
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
