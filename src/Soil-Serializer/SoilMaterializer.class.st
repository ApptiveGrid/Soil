Class {
	#name : #SoilMaterializer,
	#superclass : #SoilBasicMaterializer,
	#category : #'Soil-Serializer'
}

{ #category : #'as yet unclassified' }
SoilMaterializer class >> materializeFromBytes: aByteArray [
	^ (self on: aByteArray readStream)
		materialize
]

{ #category : #'reading - basic' }
SoilMaterializer class >> nextLengthEncodedInteger [

	| value aSoilMaterializer |
	aSoilMaterializer := self new.
	value := aSoilMaterializer nextByte.
	value < 128 ifTrue: [ ^ value ].
	^ (aSoilMaterializer nextLengthEncodedInteger bitShift: 7) bitOr:
		  (value bitAnd: 127)
]

{ #category : #'as yet unclassified' }
SoilMaterializer class >> on: aReadStream [
	^ self new 
		stream: aReadStream 
]

{ #category : #public }
SoilMaterializer >> behaviorVersionsUpTo: aDescription [ 
	^ transaction behaviorVersionsUpTo: aDescription 
]

{ #category : #public }
SoilMaterializer >> materialize [
	^ self nextSoilObject
]

{ #category : #public }
SoilMaterializer >> materializeFromBytes: aByteArray [
	^ (self stream: aByteArray readStream)
		materialize
]

{ #category : #'instance creation' }
SoilMaterializer >> newObject [

	^ self nextBehaviorDescription newObjectWith: self
]

{ #category : #reading }
SoilMaterializer >> nextArray: aClass [ 
	| array |
	array := aClass new: self nextLengthEncodedInteger.
	self registerObject: array.
	1 to: array size do: [ :index | array at: index put: self nextSoilObject ].
	^ array
]

{ #category : #reading }
SoilMaterializer >> nextAssociation: aClass [ 
	| association |
	association := aClass new.
	self registerObject: association.
	^ association
		key: self nextSoilObject;
		value: self nextSoilObject
]

{ #category : #reading }
SoilMaterializer >> nextBehaviorDescription [
	| behaviorIndex behaviorVersion |
	behaviorIndex := self nextLengthEncodedInteger.
	behaviorVersion := self nextLengthEncodedInteger.
	^ behaviorIndex isZero
		ifTrue: [ SOBehaviorDescription meta ]
		ifFalse: [
			transaction
				behaviorDescriptionWithIndex: behaviorIndex
				andVersion: behaviorVersion ]
]

{ #category : #reading }
SoilMaterializer >> nextClass [
	^ Smalltalk 
		at: self nextString asSymbol 
		ifAbsent: nil
]

{ #category : #reading }
SoilMaterializer >> nextCompiledBlock: aClass [

 	| header bytecodesSize compiledBlock |

 	header := self nextSoilObject.
 	bytecodesSize := self nextLengthEncodedInteger.
	
 	compiledBlock := aClass
 		newMethod: bytecodesSize
 		header: header.
	
	self registerObject: compiledBlock.

 	"first the literals
 	note: we omit the outer code here as we store clean blocks"
 	1 to: compiledBlock numLiterals - 1 do: [:i | 
 				compiledBlock literalAt: i put: self nextSoilObject ].			

 	compiledBlock initialPC 
 		to: compiledBlock size
 		do: [ :index |
 			compiledBlock
 				at: index
 				put: self nextByte ].

 	^compiledBlock
]

{ #category : #reading }
SoilMaterializer >> nextCompiledMethod: aClass [

 	| header bytecodesPlusTrailerSize compiledMethod |

 	header :=  self nextSoilObject.
 	bytecodesPlusTrailerSize := self nextLengthEncodedInteger.

 	compiledMethod := aClass
 		newMethod: bytecodesPlusTrailerSize
 		header: header.

	self registerObject: compiledMethod.

 	"first the literals"	
 	"for now we do store the class pointer in the last literal"	
 	1 to: compiledMethod numLiterals do: [:i | 
 				compiledMethod literalAt: i  put: self nextSoilObject ].			

 	"then the bytecodes, we ignore the trailer for now"
 	compiledMethod initialPC 
 		to: compiledMethod size - compiledMethod trailer size
 		do: [ :index |
 			compiledMethod
 				at: index
 				put: self nextByte ].
	
 	^compiledMethod
]

{ #category : #reading }
SoilMaterializer >> nextDictionary: aClass [ 
	| size dict key |
	size := self nextLengthEncodedInteger.
	dict := aClass new: size.
	self registerObject: dict.
	size timesRepeat: [
		key := self nextSoilObject.
		dict at: key put: self nextSoilObject.
	].
	^dict
]

{ #category : #reading }
SoilMaterializer >> nextExternalReference [
	| index |
	index := self nextLengthEncodedInteger.
	^ externalObjectRegistry referenceAt: index
]

{ #category : #reading }
SoilMaterializer >> nextInternalReference [
	| index |
	index := self nextLengthEncodedInteger.
	^ objects at: index
]

{ #category : #reading }
SoilMaterializer >> nextMessage: aClass [ 
	| message |
	message := aClass new.
	self registerObject: message.
	^ message
		setSelector: self nextSoilObject arguments: self nextSoilObject;
		yourself
]

{ #category : #reading }
SoilMaterializer >> nextMessageSend: aClass [

	| messageSend |
	messageSend := aClass new.
	self registerObject: messageSend.
	^ messageSend
		  receiver: self nextSoilObject;
		  selector: self nextSoilObject;
		  arguments: self nextSoilObject;
		  yourself
]

{ #category : #reading }
SoilMaterializer >> nextOrderedCollection: aClass [ 
		| size collection |
	size := self  nextLengthEncodedInteger.
	collection := aClass new: size.
	self registerObject: collection.
	size timesRepeat: [ collection addLast: self nextSoilObject ].
	^ collection
]

{ #category : #reading }
SoilMaterializer >> nextPersistentDictionary: aClass [ 
	| size dict key |
	size := self nextLengthEncodedInteger.
	dict := aClass new: size.
	self registerObject: dict.
	size timesRepeat: [
		key := self nextSoilObject.
		dict at: key put: self nextSoilObject.
	].
	^dict
]

{ #category : #reading }
SoilMaterializer >> nextSoilObject [ 
	^ (TypeCodeMapping at: self nextByte) soilMaterialize: self 
]

{ #category : #registry }
SoilMaterializer >> registerObject: anObject [
	objects add: anObject 
]

{ #category : #accessing }
SoilMaterializer >> stream [
	^stream
]
