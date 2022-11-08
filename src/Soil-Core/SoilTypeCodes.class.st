Class {
	#name : #SoilTypeCodes,
	#superclass : #SharedPool,
	#classVars : [
		'TypeCodeArray',
		'TypeCodeAssociation',
		'TypeCodeByteArray',
		'TypeCodeByteCharacter',
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
		'TypeCodeLargeNegativeInteger',
		'TypeCodeLargePositiveInteger',
		'TypeCodeMapping',
		'TypeCodeMessage',
		'TypeCodeMessageSend',
		'TypeCodeObject',
		'TypeCodeOrderedCollection',
		'TypeCodeProcessScheduler',
		'TypeCodeScaledDecimal',
		'TypeCodeString',
		'TypeCodeSymbol',
		'TypeCodeSystemDictionary',
		'TypeCodeTime',
		'TypeCodeTrue',
		'TypeCodeUndefined',
		'TypeCodeWideString',
		'TypeCodeWideSymbol'
	],
	#category : #'Soil-Core-Serialization'
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
		at: TypeCodeByteCharacter 			put: [ :materializer | materializer nextByteCharacter];
		at: TypeCodeClass 						put: Class;
		at: TypeCodeString 					put: String;
		at: TypeCodeDate 						put: Date;
		at: TypeCodeDictionary 				put: Dictionary;
		at: TypeCodeFraction 					put: Fraction;
		at: TypeCodeInternalReference 		put: [ :materializer | materializer nextInternalReference ];
		at: TypeCodeExternalReference  	put: [ :materializer | materializer nextExternalReference ];
		at: TypeCodeIdentityDictionary 	put: IdentityDictionary;
		at: TypeCodeProcessScheduler  		put: Processor;
		at: TypeCodeScaledDecimal 			put: ScaledDecimal;
		at: TypeCodeSystemDictionary 		put: Smalltalk globals;
		at: TypeCodeWideSymbol 				put: WideSymbol;
		at: TypeCodeMessage 					put: Message;
		at: TypeCodeMessageSend  			put: MessageSend;
		at: TypeCodeOrderedCollection   	put: OrderedCollection;
		at: TypeCodeSymbol 					put: ByteSymbol;
		at: TypeCodeTime 						put: Time;
		at: TypeCodeWideString 				put: WideString;
		at: TypeCodeCharacter 				put: Character;
		at: TypeCodeCompiledBlock  			put: CompiledBlock;
		at: TypeCodeCompiledMethod 			put: CompiledMethod.
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
	TypeCodeByteCharacter := 11.
	TypeCodeClass := 12.
	TypeCodeString := 13.
	TypeCodeDate := 14.
	TypeCodeDictionary := 15.
	TypeCodeFraction := 16.
	TypeCodeInternalReference := 17.
	TypeCodeExternalReference := 18.
	TypeCodeIdentityDictionary := 19.
	TypeCodeProcessScheduler := 20.
	TypeCodeScaledDecimal := 21.
	TypeCodeSystemDictionary := 22.
	TypeCodeWideSymbol := 23.
	TypeCodeMessage := 24.
	TypeCodeMessageSend := 25.
	TypeCodeOrderedCollection := 26.
	TypeCodeSymbol := 27.
	TypeCodeTime := 28.
	TypeCodeWideString := 29.
	TypeCodeCharacter := 30.
	TypeCodeCompiledBlock := 31.
	TypeCodeCompiledMethod := 32


]
