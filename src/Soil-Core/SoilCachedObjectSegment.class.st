Class {
	#name : #SoilCachedObjectSegment,
	#superclass : #SoilObjectSegment,
	#instVars : [
		'cache'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #converting }
SoilCachedObjectSegment >> asCachedSegment [ 
	^ self
]

{ #category : #accessing }
SoilCachedObjectSegment >> at: anInteger [ 
	^ (cache 
		at: anInteger 
		ifAbsentPut: [ super at: anInteger ]) copy
]

{ #category : #accessing }
SoilCachedObjectSegment >> at: anInteger putBytes: bytes [ 
	| position |
	position := super at: anInteger putBytes: bytes.
	cache 
		at: anInteger 
		put: ((SoilPersistentClusterVersion readFrom: bytes readStream)
			objectId: (SoilObjectId segment: id index: anInteger);
			position: position;
			yourself).
	^ position
]

{ #category : #accessing }
SoilCachedObjectSegment >> cache [
	^ cache
]

{ #category : #initialization }
SoilCachedObjectSegment >> initialize [ 
	super initialize.
	self halt.
	cache := LRUCache new
]

{ #category : #initialization }
SoilCachedObjectSegment >> resetCache [
	cache := LRUCache new
]

{ #category : #accessing }
SoilCachedObjectSegment >> weight: anInteger [ 
	cache maximumWeight: anInteger 
]
