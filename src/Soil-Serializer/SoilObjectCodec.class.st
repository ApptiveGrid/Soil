Class {
	#name : #SoilObjectCodec,
	#superclass : #Object,
	#instVars : [
		'externalObjectRegistry',
		'stream',
		'objects',
		'transaction',
		'soil'
	],
	#classVars : [
		'CharacterEncoder'
	],
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Serializer'
}

{ #category : #accessing }
SoilObjectCodec class >> characterEncoder [

	^ CharacterEncoder
]

{ #category : #accessing }
SoilObjectCodec class >> characterEncoding: aString [
	CharacterEncoder := aString asZnCharacterEncoder
]

{ #category : #convenience }
SoilObjectCodec class >> decodeBytes: aByteArray [
	^ CharacterEncoder decodeBytes: aByteArray
]

{ #category : #convenience }
SoilObjectCodec class >> encodeString: aString [
	^ CharacterEncoder encodeString: aString
]

{ #category : #accessing }
SoilObjectCodec >> externalObjectRegistry: anObject [

	externalObjectRegistry := anObject
]

{ #category : #accessing }
SoilObjectCodec >> soil [

	^ soil
]

{ #category : #accessing }
SoilObjectCodec >> soil: anObject [

	soil := anObject
]

{ #category : #accessing }
SoilObjectCodec >> stream: aStream [
	stream := aStream
]

{ #category : #accessing }
SoilObjectCodec >> transaction: aSOTransaction [
	transaction := aSOTransaction
]
