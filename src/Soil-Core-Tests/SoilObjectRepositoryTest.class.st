Class {
	#name : #SoilObjectRepositoryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SoilObjectRepositoryTest >> setUp [ 
	super setUp.
	soil := (Soil new path: 'soil-tests')
		destroy; 
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SoilObjectRepositoryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilObjectRepositoryTest >> testFirstSegment [ 
	self assert: soil objectRepository firstSegment id equals: 1
]

{ #category : #tests }
SoilObjectRepositoryTest >> testSegmentCreation [	
	soil objectRepository addNewSegment.
	self assert: ('soil-tests' asFileReference / #segments / '2') exists.
	self assert: soil objectRepository segments size equals: 2.

]

{ #category : #tests }
SoilObjectRepositoryTest >> testSegmentInitializationFromDisk [ 
	soil objectRepository instVarNamed: #segments put: nil.
	('soil-tests' asFileReference / #segments / '1') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '2') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '3') ensureCreateDirectory.
	self assert: soil objectRepository segments size equals: 3.

]
