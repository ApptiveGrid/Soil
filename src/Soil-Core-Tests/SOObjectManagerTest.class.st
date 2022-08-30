Class {
	#name : #SOObjectManagerTest,
	#superclass : #TestCase,
	#instVars : [
		'reference',
		'label'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectManagerTest >> testStoreObject [ 
	| manager id obj |
	manager := SOObjectManager new.
	manager index: (SOObjectIndexFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeDatabase;
		yourself).
	manager objects: (SOObjectFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeDatabase;
		yourself).
	id := manager storeNewObject: #[ 1 2 3 ].
	obj := manager objectAt: id.
	self assert: obj equals: #[ 1 2 3 ]
]
