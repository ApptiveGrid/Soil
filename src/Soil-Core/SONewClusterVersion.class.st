Class {
	#name : #SONewClusterVersion,
	#superclass : #SOClusterRecord,
	#instVars : [
		'externalObjects'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SONewClusterVersion >> addObject: anObject reference: anObjectId [
	externalObjects addLast: anObject.
	references addLast: anObjectId
]

{ #category : #converting }
SONewClusterVersion >> asNewVersion [
	^ self
]

{ #category : #testing }
SONewClusterVersion >> hasChanged [
	^ true
]

{ #category : #accessing }
SONewClusterVersion >> indexOfExternalReference: anObject [
	| index |
	(anObject == object) ifTrue: [ ^ 0 ].
	index := externalObjects indexOf: anObject.
	(index > 0) ifTrue: [ 
		"anObject is an external object but has already been registered. Just
		returning the index of the registered reference"
		^ index ].
	transaction objectIndex 
		at: anObject
		ifPresent: [ :record | 
			"anObject is an external object. Allocate a new local index and 
			return that"
			self addObject: record object reference: record objectId.
			^ references size ]
		ifAbsent: [ | record |
			(anObject class isSoilClusterRoot) ifTrue: [ 
				"anObject could be made cluster root per class side setting. In that 
				case we add it as cluster root to the transaction so the following
				will find it"
				transaction addClusterObject: anObject.
				record := transaction objectIndex at: anObject.
				self addObject: record object reference: record objectId. 
				^ references size ]. 
			].
	^ 0
]

{ #category : #initialization }
SONewClusterVersion >> initialize [ 
	super initialize.
	externalObjects := OrderedCollection new.
]

{ #category : #printing }
SONewClusterVersion >> printOn: aStream [ 
	aStream << 'new record: '.
	objectId printOn: aStream.
	aStream << ' '.
	object printOn: aStream.
	
]

{ #category : #testing }
SONewClusterVersion >> shouldBeCommitted [
	^ true
]
