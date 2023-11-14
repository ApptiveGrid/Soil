Class {
	#name : #SoilCompareVersionsVisitor,
	#superclass : #SoilInstanceVisitor,
	#instVars : [
		'version'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #initialization }
SoilCompareVersionsVisitor >> initialize [ 
	super initialize.
	version := 0
]

{ #category : #validation }
SoilCompareVersionsVisitor >> print: aSoil [ 
	soil := aSoil.
	self visit: aSoil.
	^ (version = aSoil databaseVersion) 
		ifTrue: [ 
			'highest scanned version ', version printString, ' is the same as database version ' ]
		ifFalse: [ 
			'version=', version printString, ', database version=',aSoil databaseVersion printString ]
]

{ #category : #validation }
SoilCompareVersionsVisitor >> validate: aSoil [ 
	soil := aSoil.
	self visit: aSoil.
	(version = aSoil databaseVersion) 
		ifFalse: [ 
			Error signal: 'highest scanned version ', version printString, ' is not the same as database version ',aSoil databaseVersion printString ]
]

{ #category : #accessing }
SoilCompareVersionsVisitor >> version [
	^ version 
]

{ #category : #visiting }
SoilCompareVersionsVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilCompareVersionsVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	(aSoilPersistentClusterVersion version > version) ifTrue: [ 
		version := aSoilPersistentClusterVersion version ].
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]
