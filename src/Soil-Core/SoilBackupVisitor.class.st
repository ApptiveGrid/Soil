Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'source',
		'target'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> backup: aSoil [ 
	source := aSoil.
	self visit: source
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self visit: (aSoilObjectSegment at: 1)
]

{ #category : #visiting }
SoilBackupVisitor >> visitParameters: aSoilParameterFile [ 
	target settings 
		databaseFormatVersion: aSoilParameterFile databaseFormatVersion;
		databaseVersion: aSoilParameterFile databaseVersion;
		applicationVersion: aSoilParameterFile applicationVersion
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	target objectRepository 
		at: aSoilPersistentClusterVersion objectId
		put: aSoilPersistentClusterVersion serialize.
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: (source objectRepository at: reference) ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> visitSoil: aSoil [ 
	super visitSoil: aSoil.
	target databaseVersion: aSoil databaseVersion 
]
