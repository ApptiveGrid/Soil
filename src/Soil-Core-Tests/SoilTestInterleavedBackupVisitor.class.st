"
I am a SoilBackupVisitor that runs a block once, before I copy the first index: what a test commits there is committed while the backup runs.
"
Class {
	#name : #SoilTestInterleavedBackupVisitor,
	#superclass : #SoilBackupVisitor,
	#instVars : [
		'beforeFirstIndex'
	],
	#category : #'Soil-Core-Tests-TestData'
}

{ #category : #accessing }
SoilTestInterleavedBackupVisitor >> beforeFirstIndex: aBlock [
	beforeFirstIndex := aBlock
]

{ #category : #visiting }
SoilTestInterleavedBackupVisitor >> copyIndexAt: indexId segment: segmentId [
	beforeFirstIndex ifNotNil: [ :block |
		beforeFirstIndex := nil.
		block value ].
	^ super copyIndexAt: indexId segment: segmentId
]
