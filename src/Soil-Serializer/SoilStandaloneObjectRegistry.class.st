Class {
	#name : #SoilStandaloneObjectRegistry,
	#superclass : #Object,
	#instVars : [
		'classes'
	],
	#category : #'Soil-Serializer'
}

{ #category : #'instance creation' }
SoilStandaloneObjectRegistry class >> readFrom: aStream [ 
	^ self new 
		readFrom: aStream
]

{ #category : #accessing }
SoilStandaloneObjectRegistry >> behaviorDescriptionAt: anInteger [ 
	^ (SoilBehaviorDescription for: (classes at: anInteger))
		objectId: (SoilObjectId segment: 0 index: anInteger); 
		yourself 

]

{ #category : #'as yet unclassified' }
SoilStandaloneObjectRegistry >> behaviorDescriptionWithObjectId: aSoilObjectId andVersion: version [
	^ SoilBehaviorDescription for: (classes at: aSoilObjectId index)
]

{ #category : #accessing }
SoilStandaloneObjectRegistry >> indexOfBehaviorDescription: aClass [ 
	| index |
	(classes includes: aClass) 
		ifTrue: [ index := classes indexOf: aClass ]
		ifFalse: [ 
			classes add: aClass.
			index := classes size ].
	^ index
]

{ #category : #accessing }
SoilStandaloneObjectRegistry >> indexOfExternalReference: aCollection [ 
	^ 0
]

{ #category : #initialization }
SoilStandaloneObjectRegistry >> initialize [ 
	super initialize.
	classes := OrderedCollection new
]

{ #category : #'instance creation' }
SoilStandaloneObjectRegistry >> readFrom: aStream [ 
	| size |
	size := aStream nextLengthEncodedInteger.
	classes := OrderedCollection new.
	size timesRepeat: [ 
		 classes add: (Smalltalk globals at: (aStream next: (aStream nextLengthEncodedInteger)) asString  asSymbol) ]
]

{ #category : #writing }
SoilStandaloneObjectRegistry >> writeOn: aStream [ 
	aStream nextPutLengthEncodedInteger: classes size.
	classes do: [ :cls |
		aStream 
			nextPutLengthEncodedInteger: cls name size;
			nextPutAll: cls name asByteArray.
		 ]
]
