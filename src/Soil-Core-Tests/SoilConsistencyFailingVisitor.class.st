Class {
	#name : #SoilConsistencyFailingVisitor,
	#superclass : #SoilConsistencyVisitor,
	#category : #'Soil-Core-Tests'
}

{ #category : #testing }
SoilConsistencyFailingVisitor >> checkCluster: cluster [
	"test support: inject an inconsistency, captured through the normal check:using: path"
	self check: cluster using: [ Error signal: 'injected inconsistency' ]
]
