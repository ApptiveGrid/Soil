Class {
	#name : #SoilReferenceFinder,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'objectId',
		'references'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #private }
SoilReferenceFinder >> find: aSoilObjectId [ 
	objectId := aSoilObjectId.
	self visit: soil
]

{ #category : #initialization }
SoilReferenceFinder >> initialize [ 
	super initialize.
	references := OrderedCollection new
]

{ #category : #accessing }
SoilReferenceFinder >> objects [ 
	^ references collect: [ :ref |
		transaction objectWithId: ref objectId ]
]

{ #category : #visiting }
SoilReferenceFinder >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilReferenceFinder >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: reference ].
	(aSoilPersistentClusterVersion includesReference: objectId) ifTrue: [ 
		references add: aSoilPersistentClusterVersion ].
	^ aSoilPersistentClusterVersion 
]
