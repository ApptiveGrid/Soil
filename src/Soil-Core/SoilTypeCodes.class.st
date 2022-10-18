Class {
	#name : #SoilTypeCodes,
	#superclass : #SharedPool,
	#classVars : [
		'TypeCodeArray',
		'TypeCodeAssociation',
		'TypeCodeByteArray',
		'TypeCodeCharacter',
		'TypeCodeClass',
		'TypeCodeDoubleByteCharacter',
		'TypeCodeFalse',
		'TypeCodeFloat',
		'TypeCodeLargeNegativeInteger',
		'TypeCodeLargePositiveInteger',
		'TypeCodeMapping',
		'TypeCodeObject',
		'TypeCodeString',
		'TypeCodeTrue',
		'TypeCodeUndefined'
	],
	#category : #'Soil-Core'
}

{ #category : #initialization }
SoilTypeCodes class >> initialize [ 
	self initializeTypeCodes.
	self initializeTypeCodeMapping 
]

{ #category : #initialization }
SoilTypeCodes class >> initializeTypeCodeMapping [
	<script>

	TypeCodeMapping := Array new: 255.
	TypeCodeMapping
		at: TypeCodeObject              	put: [ :materializer | materializer newObject ];
		at: TypeCodeUndefined 				put: UndefinedObject;
		at: TypeCodeLargePositiveInteger 	put: [ :materializer | materializer nextLargePositiveInteger ];
		at: TypeCodeLargeNegativeInteger 	put: [ :materializer | materializer nextLargeNegativeInteger ];
		at: TypeCodeArray 						put: Array;
		at: TypeCodeAssociation 				put: Association;
		at: TypeCodeTrue 						put: true;
		at: TypeCodeFalse 						put: false;
		at: TypeCodeFloat 						put: Float;
		at: TypeCodeByteArray 				put: ByteArray;
		at: TypeCodeCharacter 				put: Character;
		at: TypeCodeClass 						put: Class;
		at: TypeCodeString 					put: String
]

{ #category : #initialization }
SoilTypeCodes class >> initializeTypeCodes [ 
	<script>
	TypeCodeObject := 1.
	TypeCodeUndefined := 2.
	TypeCodeLargePositiveInteger := 3.
	TypeCodeLargeNegativeInteger := 4.
	TypeCodeArray := 5.
	TypeCodeAssociation := 6.
	TypeCodeTrue := 7.
	TypeCodeFalse := 8.
	TypeCodeFloat := 9.
	TypeCodeByteArray := 10.
	TypeCodeCharacter := 11.
	TypeCodeClass := 12.
	TypeCodeString := 13
]
