Class {
	#name : #SoilIndexVisitor,
	#superclass : #SoilTransactionalVisitor,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilIndexVisitor >> visitJournalFragmentFile: aFile [
]

{ #category : #visiting }
SoilIndexVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	| object |
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId | | segment |
		segment := soil objectRepository segmentAt: aSoilPersistentClusterVersion segment.
		(segment indexManager hasIndexId: indexId) ifFalse: [ 
			object := aSoilPersistentClusterVersion 
				transaction: transaction;
				materializeObject.
			self halt.
			Error signal: 'index with id ', indexId printString, ' cannot be found' ]  ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilIndexVisitor >> visitSkipList: aSkipList [ 
self halt.
	aSkipList path exists ifFalse: [ 
		Error signal: 'path does not exist' ].
	^ super visitSkipList: aSkipList 
]
