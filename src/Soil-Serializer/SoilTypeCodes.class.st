Class {
	#name : 'SoilTypeCodes',
	#superclass : 'SharedPool',
	#classVars : [
		'TypeCodeArray',
		'TypeCodeAssociation',
		'TypeCodeByteArray',
		'TypeCodeCharacter',
		'TypeCodeClass',
		'TypeCodeCompiledBlock',
		'TypeCodeCompiledMethod',
		'TypeCodeDate',
		'TypeCodeDictionary',
		'TypeCodeExternalReference',
		'TypeCodeFalse',
		'TypeCodeFloat',
		'TypeCodeFraction',
		'TypeCodeIdentityDictionary',
		'TypeCodeInternalReference',
		'TypeCodeMapping',
		'TypeCodeNegativeInteger',
		'TypeCodeObject',
		'TypeCodeOrderedCollection',
		'TypeCodePersistentDictionary',
		'TypeCodePositiveInteger',
		'TypeCodeProcessScheduler',
		'TypeCodeScaledDecimal',
		'TypeCodeSmalltalkImage',
		'TypeCodeString',
		'TypeCodeSymbol',
		'TypeCodeSystemDictionary',
		'TypeCodeTime',
		'TypeCodeTrue',
		'TypeCodeUUID',
		'TypeCodeUndefined',
		'TypeCodeWideString',
		'TypeCodeWideSymbol'
	],
	#category : 'Soil-Serializer-Serializer/Materializer',
	#package : 'Soil-Serializer',
	#tag : 'Serializer/Materializer'
}

{ #category : 'initialization' }
SoilTypeCodes class >> initialize [ 
	self initializeTypeCodes.
	self initializeTypeCodeMapping 
]

{ #category : 'initialization' }
SoilTypeCodes class >> initializeTypeCodeMapping [
	<script>

	TypeCodeMapping := Array new: 255.
	TypeCodeMapping
		at: TypeCodeObject              	put: [ :materializer | materializer newObject ];
		at: TypeCodeUndefined 				put: UndefinedObject;
		at: TypeCodeTrue 						put: true;
		at: TypeCodeFalse 						put: false;
		at: TypeCodePositiveInteger 	   put: [ :materializer | materializer nextLargePositiveInteger ];
		at: TypeCodeNegativeInteger 	   put: [ :materializer | materializer nextLargeNegativeInteger ];
		at: TypeCodeFloat 						put: Float;
		at: TypeCodeFraction 					put: Fraction;
		at: TypeCodeScaledDecimal 			put: ScaledDecimal;
		at: TypeCodeCharacter 				put: Character;
		at: TypeCodeArray 						put: Array;
		at: TypeCodeOrderedCollection   	put: OrderedCollection;
		at: TypeCodeByteArray 				put: ByteArray;
		at: TypeCodeString 					put: String;
		at: TypeCodeSymbol 					put: ByteSymbol;
		at: TypeCodeWideString 				put: WideString;
		at: TypeCodeWideSymbol 				put: WideSymbol;
		at: TypeCodeAssociation 				put: Association;
		at: TypeCodeDictionary 				put: Dictionary;
		at: TypeCodeIdentityDictionary 	put: IdentityDictionary;
		at: TypeCodeDate 						put: Date;
		at: TypeCodeTime 						put: Time;
		at: TypeCodeClass 						put: Class;
		at: TypeCodeCompiledBlock  			put: CompiledBlock;
		at: TypeCodeCompiledMethod 			put: CompiledMethod;
		at: TypeCodeSystemDictionary 		put: Smalltalk globals;
		at: TypeCodeSmalltalkImage 			put: Smalltalk;
		at: TypeCodeProcessScheduler  		put: Processor;
		at: TypeCodeUUID   					put: UUID;
		at: TypeCodeInternalReference 		put: [ :materializer | materializer nextInternalReference ];
		at: TypeCodeExternalReference  	put: [ :materializer | materializer nextExternalReference ];
		at: TypeCodePersistentDictionary  put: SoilPersistentDictionary
					
]

{ #category : 'initialization' }
SoilTypeCodes class >> initializeTypeCodes [ 
	<script>
	TypeCodeObject := 1.
	TypeCodeUndefined := 2.
	TypeCodeTrue := 3.
	TypeCodeFalse := 4.
	TypeCodePositiveInteger := 5.
	TypeCodeNegativeInteger := 6.
	TypeCodeFloat := 7.
	TypeCodeFraction := 8.
	TypeCodeScaledDecimal := 9.
	TypeCodeCharacter := 10.

	TypeCodeArray := 17.
	TypeCodeOrderedCollection := 18.
	TypeCodeByteArray := 19.
	TypeCodeSymbol := 20.
	TypeCodeString := 21.
	TypeCodeWideSymbol := 22.
	TypeCodeWideString := 23.
	TypeCodeAssociation := 24.
	TypeCodeDictionary := 25.
	TypeCodeIdentityDictionary := 26.
	TypeCodeDate := 27.
	TypeCodeTime := 28.

	TypeCodeClass := 49.
	TypeCodeCompiledBlock := 50.
	TypeCodeCompiledMethod := 51.
	TypeCodeSystemDictionary := 52.
	TypeCodeProcessScheduler := 53.
	TypeCodeUUID := 54.
	TypeCodeSmalltalkImage := 55.

	TypeCodeInternalReference := 65.
	TypeCodeExternalReference := 66.
	TypeCodePersistentDictionary := 67.

]
