Class {
	#name : #SOPersistentClusterVersion,
	#superclass : #SOClusterRecord,
	#instVars : [
		'changed'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SOPersistentClusterVersion >> changed: aBoolean [
	changed := aBoolean 
]

{ #category : #testing }
SOPersistentClusterVersion >> hasChanged [
	^ changed 
]

{ #category : #initialization }
SOPersistentClusterVersion >> initialize [ 
	super initialize.
	changed := false.

]

{ #category : #printing }
SOPersistentClusterVersion >> printOn: aStream [ 
	aStream << 'old record: '.
	objectId printOn: aStream.
	aStream << ' '.
	object printOn: aStream.

]

{ #category : #asserting }
SOPersistentClusterVersion >> shouldBeCommitted [ 
	^ changed & committed not
]
