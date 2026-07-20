Class {
	#name : #SoilTestGrowingRecord,
	#superclass : #Object,
	#instVars : [
		'onHasChanged',
		'changed'
	],
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #converting }
SoilTestGrowingRecord >> asNewClusterVersion [
	^ self
]

{ #category : #accessing }
SoilTestGrowingRecord >> changed: aBoolean [
	changed := aBoolean
]

{ #category : #testing }
SoilTestGrowingRecord >> hasChanged [
	onHasChanged ifNotNil: [ onHasChanged value ].
	^ changed ifNil: [ false ]
]

{ #category : #accessing }
SoilTestGrowingRecord >> onHasChanged: aBlock [
	onHasChanged := aBlock
]

{ #category : #serializing }
SoilTestGrowingRecord >> serializeObject [
	"no-op: this stub only exercises SoilAutomaticTrackingStrategy>>prepareCommit's
	objectMap traversal, not real serialization"
]
