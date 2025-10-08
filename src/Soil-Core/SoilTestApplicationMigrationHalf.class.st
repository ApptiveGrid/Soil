Class {
	#name : #SoilTestApplicationMigrationHalf,
	#superclass : #SoilApplicationMigration,
	#category : #'Soil-Core-Migration'
}

{ #category : #accessing }
SoilTestApplicationMigrationHalf >> v1: transaction [
	<applicationVersion: 1 auto: true>
	transaction root: SoilPersistentDictionary new
]

{ #category : #accessing }
SoilTestApplicationMigrationHalf >> v2: transaction [
	<applicationVersion: 2 auto: true>
	transaction root at: #two put: 2.
]

{ #category : #accessing }
SoilTestApplicationMigrationHalf >> v3: transaction [
	<applicationVersion: 3 auto: false>
	transaction root at: #three put: 3
]

{ #category : #accessing }
SoilTestApplicationMigrationHalf >> v4: transaction [
	<applicationVersion: 4 auto: true>
	transaction root at: #four put: 4
]
