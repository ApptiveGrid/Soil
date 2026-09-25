"
I am a SoilGraphImporter a test can hold between taking its ids and writing its clusters: I signal #arrived there and wait for #proceed.
"
Class {
	#name : #SoilTestGatedGraphImporter,
	#superclass : #SoilGraphImporter,
	#instVars : [
		'arrived',
		'proceed'
	],
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestGatedGraphImporter >> arrived [
	^ arrived
]

{ #category : #initialization }
SoilTestGatedGraphImporter >> initialize [
	super initialize.
	arrived := Semaphore new.
	proceed := Semaphore new
]

{ #category : #accessing }
SoilTestGatedGraphImporter >> proceed [
	^ proceed
]

{ #category : #reading }
SoilTestGatedGraphImporter >> readClusters [
	arrived signal.
	proceed wait.
	super readClusters
]
