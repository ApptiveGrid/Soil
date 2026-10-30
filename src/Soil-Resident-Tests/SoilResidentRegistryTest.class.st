"
What an embedder asks of the persisted registry by name: whether a resident is
there, which ones are, and taking one out again. Nothing in Soil itself asks it
-- the embedder decides which residents a database has -- so without these tests
the selectors would count as unsent in Soil's own build.

The registry is a plain object until it is written, so none of this needs a
database.
"
Class {
	#name : #SoilResidentRegistryTest,
	#superclass : #TestCase,
	#instVars : [
		'registry'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #running }
SoilResidentRegistryTest >> setUp [
	super setUp.
	registry := SoilResidentRegistry new
]

{ #category : #tests }
SoilResidentRegistryTest >> testIncludesNameAnswersWhetherADescriptionIsThere [
	"how an embedder that adds its residents on open tells a new database from one
	that has them already"
	self deny: (registry includesName: #dummy).
	registry addDescription: SoilTestResidentDescription new.
	self assert: (registry includesName: #dummy).
	self deny: (registry includesName: #passive)
]

{ #category : #tests }
SoilResidentRegistryTest >> testNamesAreTheNamesOfTheDescriptions [
	self assert: registry names isEmpty.
	registry
		addDescription: SoilTestResidentDescription new;
		addDescription: SoilTestPassiveResidentDescription new.
	self assert: registry names asSet equals: #( #dummy #passive ) asSet
]

{ #category : #tests }
SoilResidentRegistryTest >> testRemovingADescriptionFreesItsName [
	"the name is free again afterwards: adding under it is no longer refused"
	| description |
	description := registry addDescription: SoilTestResidentDescription new.
	self assert: (registry removeDescriptionNamed: #dummy) identicalTo: description.
	self deny: (registry includesName: #dummy).
	registry addDescription: SoilTestResidentDescription new.
	self assert: (registry includesName: #dummy)
]

{ #category : #tests }
SoilResidentRegistryTest >> testRemovingAnAbsentNameAnswersNil [
	self assert: (registry removeDescriptionNamed: #nothingHere) isNil
]
