Class {
	#name : #SoilObjectProxy,
	#superclass : #ProtoObject,
	#instVars : [
		'transaction',
		'objectId',
		'object'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #converting }
SoilObjectProxy >> asSoilObjectId [ 
	^ objectId 
]

{ #category : #converting }
SoilObjectProxy >> asUnresolvedProxy [ 
	^ SoilUnresolvedProxy new
		objectId: objectId 
]

{ #category : #'class membership' }
SoilObjectProxy >> class [
	"we override it here as else the superclass version would be uses, returning SoilObjectProxy"
    ^ self soilRealObject class
]

{ #category : #'reflective operations' }
SoilObjectProxy >> doesNotUnderstand: aMessage [ 
	^ aMessage sendTo: self soilRealObject
]

{ #category : #fuel }
SoilObjectProxy >> fuelAccept: aGeneralMapper [ 	
	^ aGeneralMapper 
		visitSubstitution: self 
		by: (object ifNil: [ self asUnresolvedProxy ])
]

{ #category : #fuel }
SoilObjectProxy >> fuelReplacement [
	"proxies should not be serialized. If the object has already been
	resolved then we can replace the proxy with the object. If the object 
	is not loaded we replace it with an unresolved proxy keepig the objectId"
	^ object ifNil: [ self asUnresolvedProxy ]
]

{ #category : #inspector }
SoilObjectProxy >> inspectionObject [
	<inspectorPresentationOrder: 30 title: 'object'>
	^ StRawInspection on: self soilRealObject 

]

{ #category : #testing }
SoilObjectProxy >> isEqualTo: anObject [ 
	anObject isSoilProxy ifTrue: [^ objectId = anObject objectId].
	(anObject isNil or: [ self objectIsNotLoaded ]) ifTrue: [^false].
	^ object = anObject
]

{ #category : #testing }
SoilObjectProxy >> isIdenticalTo: anObject [ 
	anObject isSoilProxy ifTrue: [^ objectId = anObject objectId].
	(anObject isNil or: [ self objectIsNotLoaded ]) ifTrue: [^false].
	^ object == anObject
]

{ #category : #testing }
SoilObjectProxy >> isSoilProxy [ 
	^ true
]

{ #category : #accessing }
SoilObjectProxy >> objectId [

	^ objectId
]

{ #category : #accessing }
SoilObjectProxy >> objectId: anObject [

	objectId := anObject
]

{ #category : #soil }
SoilObjectProxy >> objectIsNotLoaded [

	"a present object is loaded"
	object ifNotNil: [ ^ false ].
	"it is also loaded if the transaction has it."
	object := transaction 
		objectAt: objectId 
		ifAbsent: [ ^ true ].
	^ false
]

{ #category : #printing }
SoilObjectProxy >> printOn: aStream [ 
	aStream << 'proxy ' << objectId asString.
	object ifNotNil: [ 
		aStream <<  ': '.
		object printOn: aStream ]
]

{ #category : #printing }
SoilObjectProxy >> printString [ 
	^ String streamContents: [ :s | self printOn: s ] limitedTo: 1000 
]

{ #category : #soil }
SoilObjectProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #'reflective operations' }
SoilObjectProxy >> soilRealObject [
	^ object ifNil: [  
		object := transaction objectWithId: objectId ]
]

{ #category : #soil }
SoilObjectProxy >> soilSerialize: aSerializer [ 
	^ self soilRealObject soilSerialize: aSerializer 
]

{ #category : #soil }
SoilObjectProxy >> theNonSoilProxy [ 
	^ self soilRealObject
]

{ #category : #accessing }
SoilObjectProxy >> transaction [

	^ transaction
]

{ #category : #accessing }
SoilObjectProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
