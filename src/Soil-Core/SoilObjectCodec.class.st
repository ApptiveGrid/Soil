Class {
	#name : #SoilObjectCodec,
	#superclass : #Object,
	#classVars : [
		'characterEncoder'
	],
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core'
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
