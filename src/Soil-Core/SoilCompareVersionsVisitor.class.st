Class {
	#name : #SoilCompareVersionsVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'maxVersion'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #initialization }
SoilCompareVersionsVisitor >> initialize [ 
	super initialize.
	maxVersion := 0
]

{ #category : #validation }
SoilCompareVersionsVisitor >> print: aSoil [ 
	soil := aSoil.
	self visit: aSoil.
	^ (maxVersion = aSoil control databaseVersion) 
		ifTrue: [ 
			'highest scanned version ', maxVersion printString, ' is the same as database version ' ]
		ifFalse: [ 
			'version=', maxVersion printString, ', database version=',aSoil databaseVersion printString ]
]

{ #category : #validation }
SoilCompareVersionsVisitor >> validate: aSoil [ 
	soil := aSoil.
	self visit: aSoil.
	(maxVersion = aSoil control databaseVersion) 
		ifFalse: [ 
			Error signal: 'highest scanned version ', maxVersion printString, ' is not the same as database version ',aSoil databaseVersion printString ]
]

{ #category : #accessing }
SoilCompareVersionsVisitor >> version [
	^ maxVersion 
]

{ #category : #visiting }
SoilCompareVersionsVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilCompareVersionsVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	(aSoilPersistentClusterVersion version > maxVersion) ifTrue: [ 
		maxVersion := aSoilPersistentClusterVersion version ].
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]
