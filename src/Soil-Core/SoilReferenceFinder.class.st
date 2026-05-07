Class {
	#name : #SoilReferenceFinder,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'objectId',
		'references',
		'metaSearch'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #private }
SoilReferenceFinder >> find: aSoilObjectId [ 
	objectId := aSoilObjectId.
	metaSearch := objectId segment isZero.
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

{ #category : #accessing }
SoilReferenceFinder >> records [
	^ references collect: [ :ref |
		transaction recordWithId: ref objectId ]
]

{ #category : #accessing }
SoilReferenceFinder >> references [
	^ references
]

{ #category : #visiting }
SoilReferenceFinder >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilReferenceFinder >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: reference ].
	metaSearch 
		ifTrue: [
			(aSoilPersistentClusterVersion includesBehaviorDescription: objectId) ifTrue: [ 
				references add: aSoilPersistentClusterVersion ] ]
		ifFalse: [ 
			(aSoilPersistentClusterVersion includesReference: objectId) ifTrue: [ 
				references add: aSoilPersistentClusterVersion ] ].
		
	^ aSoilPersistentClusterVersion 
]
