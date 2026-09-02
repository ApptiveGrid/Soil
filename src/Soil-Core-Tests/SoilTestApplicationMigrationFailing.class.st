Class {
	#name : #SoilTestApplicationMigrationFailing,
	#superclass : #SoilApplicationMigration,
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestApplicationMigrationFailing >> v1: transaction [
	<applicationVersion: 1 auto: true>
	transaction root: SoilPersistentDictionary new
]

{ #category : #accessing }
SoilTestApplicationMigrationFailing >> v2: transaction [
	<applicationVersion: 2 auto: true>
	transaction root at: #two put: 2
]

{ #category : #accessing }
SoilTestApplicationMigrationFailing >> v3: transaction [
	<applicationVersion: 3 auto: true>
	transaction root at: #three put: 3.
	Error signal: 'this version cannot be applied'
]

{ #category : #accessing }
SoilTestApplicationMigrationFailing >> v4: transaction [
	<applicationVersion: 4 auto: true>
	transaction root at: #four put: 4
]
