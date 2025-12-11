Class {
	#name : #SoilClusterVersionTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #tests }
SoilClusterVersionTest >> testPersistentClusterVersionMemory [
	| record |
	record := SoilPersistentClusterVersion new
		version: 12;
		previousVersionPosition: 100;
		bytes: #[ 9 8 7 6 5 4 3 2 1];
		behaviorDescriptions: ({ 1 . 2 . 3 } collect: [ : each | SoilBehaviorDescription new 
			objectId: each asSoilObjectId;
			version: 10 atRandom;
			initializeFromBehavior: Point]);
		references: ({ 4 . 5 . 6 } collect: #asSoilObjectId).
	
	self assert: record soilSizeInMemory equals: 1104
]

{ #category : #tests }
SoilClusterVersionTest >> testPersistentClusterVersionRoundtrip [
	| record bytes read |
	record := SoilPersistentClusterVersion new
		version: 12;
		previousVersionPosition: 100;
		bytes: #[ 9 8 7 6 5 4 3 2 1];
		behaviorDescriptions: ({ 1 . 2 . 3 } collect: [ : each | SoilBehaviorDescription new 
			objectId: each asSoilObjectId;
			version: 10 atRandom ]);
		references: ({ 4 . 5 . 6 } collect: #asSoilObjectId).
	bytes := ByteArray streamContents: [ :stream |
		record serializeOn: stream ].
	read := SoilPersistentClusterVersion new readFrom: bytes readStream.
	self assert: read version equals: 12.
	self assert: read previousVersionPosition equals: 100.
	self assert: read bytes equals: #[ 9 8 7 6 5 4 3 2 1].
	self assertCollection: (read behaviorDescriptions collect: #index) hasSameElements: ({ 1 . 2 . 3 }).
	self assertCollection: (read references collect: #index) hasSameElements: ({ 4 . 5 . 6 })
		
		
]
