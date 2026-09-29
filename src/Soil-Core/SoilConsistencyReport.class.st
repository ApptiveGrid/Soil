"
What the consistency trackers of one walk over a database found, and the version it was read at (#of:readAt:). It is what gets stored or sent, and what a repair is started from - by a person, not by itself.
"
Class {
	#name : #SoilConsistencyReport,
	#superclass : #Object,
	#instVars : [
		'databaseVersion',
		'findings'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilConsistencyReport class >> databaseVersion: anInteger findings: aCollection [
	^ self new
		databaseVersion: anInteger findings: aCollection;
		yourself
]

{ #category : #'instance creation' }
SoilConsistencyReport class >> of: aCollectionOfConsistencyTrackers readAt: anInteger [
	"the findings of the consistency trackers of one walk; the visitor that carried them
	does not know what they collect"
	^ self 
		databaseVersion: anInteger 
		findings: (aCollectionOfConsistencyTrackers flatCollect: [ :each | each findings ])
]

{ #category : #accessing }
SoilConsistencyReport >> asDictionary [
	^ Dictionary new
		at: #databaseVersion put: databaseVersion;
		at: #findings put: (findings collect: [ :each | each asDictionary ]) asArray;
		yourself
]

{ #category : #accessing }
SoilConsistencyReport >> databaseVersion [
	^ databaseVersion
]

{ #category : #initialization }
SoilConsistencyReport >> databaseVersion: anInteger findings: aCollection [
	databaseVersion := anInteger.
	findings := aCollection asOrderedCollection
]

{ #category : #accessing }
SoilConsistencyReport >> findings [
	^ findings
]

{ #category : #testing }
SoilConsistencyReport >> isEmpty [
	^ findings isEmpty
]

{ #category : #printing }
SoilConsistencyReport >> printOn: aStream [
	aStream << 'consistency report at version ' << databaseVersion printString << ': '.
	findings 
		ifEmpty: [ aStream << 'nothing found' ]
		ifNotEmpty: [ findings 
			do: [ :each | each printOn: aStream ]
			separatedBy: [ aStream << '; ' ] ]
]
