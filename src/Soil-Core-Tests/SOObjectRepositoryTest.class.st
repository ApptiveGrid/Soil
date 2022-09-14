Class {
	#name : #SOObjectRepositoryTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentCreation [
	| disk soil |
	disk := FileSystem memory.
	soil := Soil path: disk root.
	soil initializeFilesystem.
	soil objectRepository addNewSegment.
	self assert: (disk root / #segments / '2') exists.
	self assert: soil objectRepository segments size equals: 2.

]

{ #category : #tests }
SOObjectRepositoryTest >> testSegmentInitializationFromDisk [ 
	| disk soil |
	disk := FileSystem memory.
	soil := Soil path: disk root.
	soil initializeFilesystem.
	soil objectRepository instVarNamed: #segments put: nil.
	(disk root / #segments / '1') ensureCreateDirectory.
	(disk root / #segments / '2') ensureCreateDirectory.
	(disk root / #segments / '3') ensureCreateDirectory.
	self assert: soil objectRepository segments size equals: 3.

]
