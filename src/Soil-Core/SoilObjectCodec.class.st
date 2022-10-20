Class {
	#name : #SoilObjectCodec,
	#superclass : #Object,
	#instVars : [
		'externalObjectRegistry',
		'stream'
	],
	#classVars : [
		'characterEncoder'
	],
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core-Serialization'
}

{ #category : #accessing }
SoilObjectCodec class >> characterEncoder [

	^ characterEncoder
]

{ #category : #accessing }
SoilObjectCodec class >> characterEncoding: aString [
	characterEncoder := aString asZnCharacterEncoder 
]

{ #category : #convenience }
SoilObjectCodec class >> decodeBytes: aByteArray [ 
	^ characterEncoder decodeBytes: aByteArray
]

{ #category : #convenience }
SoilObjectCodec class >> encodeString: aString [ 
	^ characterEncoder encodeString: aString
]

{ #category : #accessing }
SoilObjectCodec >> externalObjectRegistry: anObject [

	externalObjectRegistry := anObject
]

{ #category : #accessing }
SoilObjectCodec >> stream: aStream [ 
	stream := aStream
]
