Class {
	#name : #SoilDatabaseMigrationV2,
	#superclass : #SoilDatabaseMigration,
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilDatabaseMigrationV2 class >> migratesFormatVersion [
	^ 1
]

{ #category : #visiting }
SoilDatabaseMigrationV2 >> visitDatabaseJournal: aSoilJournal [ 
	"we don't need to go into the journal"
]

{ #category : #visiting }
SoilDatabaseMigrationV2 >> visitIndex: anIndex [ 
	"for version 2 of the database the indexes change to version 3 which is not 
	backward compatible. It introduced back links for pages so that a mixed 
	version of pages is not possible. But the mechanics for migrating is still 
	doing a compact which reads the index in its old format and writes the new
	one"
	anIndex compact
]
