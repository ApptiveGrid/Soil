Class {
	#name : #SoilTestMigration,
	#superclass : #SoilApplicationMigration,
	#instVars : [
		'method'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilTestMigration class >> applicationVersion [
	^ 2
]

{ #category : #accessing }
SoilTestMigration >> v1: transaction [
	<applicationVersion: 1 auto: true>
	transaction root: Object new
]

{ #category : #accessing }
SoilTestMigration >> v2: transaction [
	<applicationVersion: 2 auto: false>
	transaction root: Object new
]
