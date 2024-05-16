"
Abstract superclass of both the Serializer and the Materializer
"
Class {
	#name : 'SoilObjectCodec',
	#superclass : 'Object',
	#instVars : [
		'externalObjectRegistry',
		'stream',
		'transaction',
		'soil'
	],
	#classVars : [
		'CharacterEncoder'
	],
	#pools : [
		'SoilTypeCodes'
	],
	#category : 'Soil-Serializer-Serializer/Materializer',
	#package : 'Soil-Serializer',
	#tag : 'Serializer/Materializer'
}

{ #category : 'accessing' }
SoilObjectCodec class >> characterEncoder [

	^ CharacterEncoder
]

{ #category : 'accessing' }
SoilObjectCodec class >> characterEncoding: aString [
	CharacterEncoder := aString asZnCharacterEncoder 
]

{ #category : 'convenience' }
SoilObjectCodec class >> decodeBytes: aByteArray [ 
	^ CharacterEncoder decodeBytes: aByteArray
]

{ #category : 'convenience' }
SoilObjectCodec class >> encodeString: aString [ 
	^ CharacterEncoder encodeString: aString
]

{ #category : 'class initialization' }
SoilObjectCodec class >> initialize [
	CharacterEncoder := #utf8 asZnCharacterEncoder
]

{ #category : 'accessing' }
SoilObjectCodec >> externalObjectRegistry: anObject [

	externalObjectRegistry := anObject
]

{ #category : 'accessing' }
SoilObjectCodec >> soil [

	^ soil
]

{ #category : 'accessing' }
SoilObjectCodec >> soil: anObject [

	soil := anObject
]

{ #category : 'accessing' }
SoilObjectCodec >> stream: aStream [ 
	stream := aStream
]

{ #category : 'accessing' }
SoilObjectCodec >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
