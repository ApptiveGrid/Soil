Class {
	#name : #SoilDatabaseMigration,
	#superclass : #SoilVisitor,
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilDatabaseMigration class >> migratesFormatVersion [ 
	self subclassResponsibility 
]

{ #category : #testing }
SoilDatabaseMigration class >> migratesVersion: anInteger [ 
	^ self allSubclasses 
		detect: [ :each | each migratesFormatVersion = anInteger ]
]

{ #category : #actions }
SoilDatabaseMigration >> migrate [ 
	(soil control databaseFormatVersion = self class migratesFormatVersion) ifFalse: [ 
		self error: 'setup problem. this class cannot upgrade this soil instance' ]. 
	self visit: soil.
	soil control databaseFormatVersion: self class migratesFormatVersion + 1
]
