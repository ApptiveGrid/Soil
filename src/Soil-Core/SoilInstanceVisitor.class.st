Class {
	#name : #SoilInstanceVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilInstanceVisitor >> soil [

	^ soil
]

{ #category : #accessing }
SoilInstanceVisitor >> soil: anObject [

	soil := anObject
]

{ #category : #visiting }
SoilInstanceVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self visit: ((soil objectRepository segmentAt: aSoilPersistentClusterVersion segment) indexAt: indexId)  ].
	^ aSoilPersistentClusterVersion 
]
