Class {
	#name : #SoilStandaloneObjectRegistry,
	#superclass : #Object,
	#instVars : [
		'classes'
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
	^ (SoilBehaviorDescription for: (classes at: anInteger))
		objectId: (SoilObjectId segment: 0 index: anInteger); 
		yourself 

]

{ #category : #query }
SoilStandaloneObjectRegistry >> behaviorDescriptionWithObjectId: aSoilObjectId andVersion: version [
	^ SoilBehaviorDescription for: (classes at: aSoilObjectId index)
]

{ #category : #query }
SoilStandaloneObjectRegistry >> indexOfBehaviorDescription: aClass [ 
	^(classes includes: aClass) 
		ifTrue: [ classes indexOf: aClass ]
		ifFalse: [ 
			classes add: aClass.
			classes size ]
]

{ #category : #query }
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
	classes := OrderedCollection new: size.
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
