"
This class enables the serializer to be used without the database (and with no transaction).

As common with serializers, we only have limited support for loading objects into a system where the class changed. We asume that all classes are the same for serialization and materialization.

This class provides therefore an implementation of the API for the behavior description registration that assumes that we have only one version.
"
Class {
	#name : #SoilStandaloneObjectRegistry,
	#superclass : #Object,
	#instVars : [
		'behaviorDescriptions'
	],
	#category : #'Soil-Serializer-Base'
}

{ #category : #'instance creation' }
SoilStandaloneObjectRegistry class >> readFrom: aStream [ 
	^ self new 
		readFrom: aStream
]

{ #category : #query }
SoilStandaloneObjectRegistry >> behaviorDescriptionAt: anInteger [ 
	^ behaviorDescriptions at: anInteger
]

{ #category : #query }
SoilStandaloneObjectRegistry >> behaviorDescriptionWithObjectId: aSoilObjectId andVersion: version [
	^ behaviorDescriptions at: aSoilObjectId index
]

{ #category : #query }
SoilStandaloneObjectRegistry >> indexOfBehaviorDescription: aBehavior [
	| index |
	index := behaviorDescriptions 
		detectIndex: [ :each | each behaviorIdentifier = aBehavior name ]
		ifNone: 0.
	(index > 0) ifTrue: [ ^ index ].
	
	index :=  behaviorDescriptions size.
	behaviorDescriptions add: (
		(SoilBehaviorDescription for: (aBehavior))
			objectId: (SoilObjectId segment: 0 index: index + 1); 
			yourself
	).
	^ index + 1
]

{ #category : #query }
SoilStandaloneObjectRegistry >> indexOfExternalReference: aCollection [ 
	^ 0
]

{ #category : #initialization }
SoilStandaloneObjectRegistry >> initialize [ 
	super initialize.
	behaviorDescriptions := OrderedCollection new
]

{ #category : #'instance creation' }
SoilStandaloneObjectRegistry >> readFrom: aStream [ 
	| size |
	size := aStream nextLengthEncodedInteger.
	behaviorDescriptions := OrderedCollection new: size.
	1 to: size do: [:index | 
		 behaviorDescriptions 
			add: 
			((SoilBehaviorDescription for: (Smalltalk globals at: (aStream next: (aStream nextLengthEncodedInteger))asString asSymbol))
				objectId: (SoilObjectId segment: 0 index: index); yourself)]
]

{ #category : #writing }
SoilStandaloneObjectRegistry >> writeOn: aStream [ 
	aStream nextPutLengthEncodedInteger: behaviorDescriptions size.
	behaviorDescriptions do: [ :behaviorDescription |
		aStream 
			nextPutLengthEncodedInteger: behaviorDescription behaviorIdentifier size;
			nextPutAll: behaviorDescription behaviorIdentifier asByteArray ]
]
