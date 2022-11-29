Class {
	#name : #SOObjectRepositoryTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentCreation [
	| soil |
	soil := Soil path: 'soil-tests'.
	soil
		destroy; 
		initializeFilesystem.
	soil objectRepository addNewSegment.
	self assert: ('soil-tests' asFileReference / #segments / '2') exists.
	self assert: soil objectRepository segments size equals: 2.

]

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentInitializationFromDisk [ 
	| soil |
	soil := Soil path: 'soil-tests'.
	soil destroy; initializeFilesystem.
	soil objectRepository instVarNamed: #segments put: nil.
	('soil-tests' asFileReference / #segments / '1') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '2') ensureCreateDirectory.
	('soil-tests' asFileReference / #segments / '3') ensureCreateDirectory.
	self assert: soil objectRepository segments size equals: 3.

]
