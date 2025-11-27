Class {
	#name : #SoilTestApplicationMigrationFull,
	#superclass : #SoilApplicationMigration,
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestApplicationMigrationFull >> v1: transaction [
	<applicationVersion: 1 auto: true>
	transaction root: SoilPersistentDictionary new
]

{ #category : #accessing }
SoilTestApplicationMigrationFull >> v2: transaction [
	<applicationVersion: 2 auto: true>
	transaction root at: #two put: 2.
]

{ #category : #accessing }
SoilTestApplicationMigrationFull >> v3: transaction [
	<applicationVersion: 3 auto: true>
	transaction root at: #three put: 3
]

{ #category : #accessing }
SoilTestApplicationMigrationFull >> v4: transaction [
	<applicationVersion: 4 auto: true>
	transaction root at: #four put: 4
]
