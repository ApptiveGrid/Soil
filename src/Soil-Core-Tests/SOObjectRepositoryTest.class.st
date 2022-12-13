Class {
	#name : #SOObjectRepositoryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SOObjectRepositoryTest >> setUp [ 
	super setUp.
	soil := (Soil new path: 'soil-tests')
		destroy; 
		initializeFilesystem;
		yourself.
]

{ #category : #tests }
SOObjectRepositoryTest >> testFirstSegment [ 
	self assert: soil objectRepository firstSegment id equals: 1
]

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentCreation [	
	soil objectRepository addNewSegment.
	self assert: ('soil-tests' asFileReference / #segments / '2') exists.
	self assert: soil objectRepository segments size equals: 2.

]

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentInitializationFromDisk [ 
	soil objectRepository instVarNamed: #segments put: nil.
	('soil-tests' asFileReference / #segments / '1') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '2') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '3') ensureCreateDirectory.
	self assert: soil objectRepository segments size equals: 3.

]
