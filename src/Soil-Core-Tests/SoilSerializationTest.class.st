Class {
	#name : #SoilSerializationTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #testing }
SoilSerializationTest >> expectedFailures [ 
	^ #( testSerializationBoxedFloat64Twice testSerializationByteLayout testSerializationFractionTwice)
]

{ #category : #running }
SoilSerializationTest >> setUp [
	super setUp.
	ODBTypeCodes initialize.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationArray [
	| object serialized materialized |
	object := #(1 2 3 5).
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[5 4 3 1 3 2 3 3 3 5].
	self assert: (serialized at: 1) equals: TypeCodeArray.

	materialized := SoilMaterializer materializeFromBytes: serialized. 
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationAssociation [
	| object serialized materialized |
	object := 1 -> 2.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[6 3 1 3 2].
	self assert: (serialized at: 1) equals: TypeCodeAssociation.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationBlockClosure [
	| object serialized  |
	object := [].
	"we do not uet support serializing closures"
	self should: [serialized := ODBSerializer serializeToBytes: object] raise: TestResult error
]

{ #category : #tests }
SoilSerializationTest >> testSerializationBoxedFloat64 [
	| float serialized materialized |
	float := 2.45227231256843e-45.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[9 3 128 128 176 181 3 3 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: 2.45227231256843e-45.
	
	"can we still de-serialize the old way before we used ODBFloatCode?"
	materialized := ODBDeserializer deserializeFromBytes: 
	#[0 1 12 66 111 120 101 100 70 108 111 97 116 54 52 1 1 0 1 0 0 0 2 1 2 128 128 224 234 6 0].
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: 2.45227231256843e-45.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationBoxedFloat64Infinity [
	| float serialized materialized |
	float := Float infinity.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[9 3 128 128 192 255 7 3 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: float.
	
	float := Float negativeInfinity.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[9 3 128 128 192 255 15 3 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: float
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationBoxedFloat64Twice [
	| float object serialized materialized |
	
	"try to serialize an object that references twice the boxed floats"
	float := 2.45227231256843e-45.
	object := {float . float}.

	serialized := SoilSerializer serializeToBytes: object.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First Float"
	self assert: (serialized at: 3) equals: TypeCodeFloat.
	"Second Float: should this be an internal reference, not the float again?"
	self assert: (serialized at: 10) equals: TypeCodeFloat.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationByteArray [
	| object serialized materialized |
	object := #[1 2 3 5].
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[10 4 1 2 3 5].
	self assert: (serialized at: 1) equals: TypeCodeByteArray.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationByteLayout [
	| object serialized materialized |
	self skip.
	"We use SocketAddress as an exampe of a class with a ByteLayout but not specially encoded"
	object := #[127 0 0 1] asSocketAddress.
	
	self assert: object class classLayout class equals: ByteLayout.
	serialized := SoilSerializer serializeToBytes: object.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: SocketAddress.
	self assert: materialized class classLayout class equals: ByteLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationCharacter [
	| object serialized materialized |
	object := $a.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[11 97].
	self assert: (serialized at: 1) equals: TypeCodeCharacter.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationCharacterTwice [
	| object character serialized materialized |
	character := $a.
	object := {character. character}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First Character"
	self assert: (serialized at: 9) equals: ODBCharacterCode.
	"Second Character, they are immediate objects, so we do store them directly"
	self assert: (serialized at: 11) equals: ODBCharacterCode.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.

	character := 16rF600 asCharacter.
	object := {character. character}.

	serialized := ODBSerializer serializeToBytes: object.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.

]

{ #category : #tests }
SoilSerializationTest >> testSerializationClass [
	| object serialized materialized |
	object := Point.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[12 5 80 111 105 110 116].
	self assert: (serialized at: 1) equals: TypeCodeClass.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized  equals: Point.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationCompiledMethodLayout [
	| object serialized materialized |
	self skip.
	"Not yet implemented"
	self flag: #TODO.
	"We use CompiledMethod as an exampe of a class with a CompiledMethodLayout"
	object := (OrderedCollection>>#do:) copy.
	
	self assert: object class classLayout class equals: CompiledMethodLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class classLayout class equals: CompiledMethodLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationDate [
	| object serialized materialized |
	object := Date fromDays: 10.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[14 10 0].
	self assert: (serialized at: 1) equals: TypeCodeDate.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationDictionary [
	| object serialized materialized |
	object := { 1->2 . 3->4 } asDictionary.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[15 2 3 1 3 2 3 3 3 4].
	self assert: (serialized at: 1) equals: TypeCodeDictionary.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationDoubleByteLayout [
	| object serialized materialized |
	"We use DoubleByteArray as an exampe of a class with a DoubleByteLayout but not specially encoded"
	(SystemVersion current major < 10) ifTrue: [ self skip ].
	"Double layouts not working in Pharo9"
	object := DoubleByteArray newFrom: #(10 20 30 40).
	
	self assert: object class classLayout class equals: DoubleByteLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: DoubleByteArray.
	self assert: materialized class classLayout class equals: DoubleByteLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationDoubleWordLayout [
	| object serialized materialized |
	"We use DoubleWordArray as an exampe of a class with a DoubleWordLayout but not specially encoded"
	
	(SystemVersion current major < 10) ifTrue: [ self skip ].
	"Double layouts not working in Pharo9"
	
	object := DoubleWordArray newFrom: #(10 20 30 40).
	
	self assert: object class classLayout class equals: DoubleWordLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: DoubleWordArray.
	self assert: materialized class classLayout class equals: DoubleWordLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationEphemeronLayout [
	"Emphemeron classes are not yet used (no example in Pharo11), thus we do not support them yet"
	self flag: #TODO
]

{ #category : #tests }
SoilSerializationTest >> testSerializationFalse [
	| object serialized materialized |
	"Check false"
	object := false.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[8].
	self assert: (serialized at: 1) equals: TypeCodeFalse.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self deny: materialized
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationFixedLayout [
	| object serialized materialized |
	"We use Point as an exampe of a class with a FixedLayout but not specially encoded"
	object := 4@3.
	
	self assert: object class classLayout class equals: FixedLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: Point.
	self assert: materialized class classLayout class equals: FixedLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationFraction [
	| object serialized materialized |
	object := 1/2.
	self assert: object class equals: Fraction.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[16 1 2].
	self assert: (serialized at: 1) equals: TypeCodeFraction.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationFractionTwice [
	| fraction object serialized materialized |
	fraction := 1/2.
	object := {fraction . fraction}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First Fraction"
	self assert: (serialized at: 3) equals: TypeCodeFraction.
	"Second Fraction, reference to the first"
	self assert: (serialized at: 6) equals: TypeCodeInternalReference.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationIdentityDictionary [
	| object serialized materialized |
	object := IdentityDictionary newFrom: { #test->2 . #now->4 }.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: (
			serialized = 
			"the order of association in the dict is different between Pharo9 and Pharo10, no idea why"
			#[19 2 1 1 4 3 2 1 1 3 3 4] 
		or: [ 
			serialized = 
			#[0 0 1 0 0 0 38 2 18 4 116 101 115 116 52 18 3 110 111 119 54]]).

	self assert: (serialized at: 1) equals: TypeCodeIdentityDictionary.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationLargeInteger [
	| object serialized materialized |
	
	"Integers are small if they are in between -3 and 16"
	"The test in addition tests LargeIntegers, but for the databse, they are just the same"
	
	object := 17.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 11 17].
	self assert: (serialized at: 7) equals: ODBLargePositiveIntegerCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	object := -4.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 12 4].
	self assert: (serialized at: 7) equals: ODBLargeNegativeIntegerCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	
	object := SmallInteger maxVal + 1.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 11 128 128 128 128 128 128 128 128 16].
	self assert: (serialized at: 7) equals: ODBLargePositiveIntegerCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	"Negative"
	object := SmallInteger minVal - 1.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 12 129 128 128 128 128 128 128 128 16].
		self assert: (serialized at: 7) equals: ODBLargeNegativeIntegerCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationLargeIntegerTwice [

	| object integer serialized materialized |
	
	"LargeInteger"
	
	integer := SmallInteger maxVal + 1.
	object := {integer. integer}.

	serialized := ODBSerializer serializeToBytes: object.
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First LargeInteger"
	self assert: (serialized at: 9) equals: ODBLargePositiveIntegerCode.
	"Second LargeInteger, reference to the first"
	self assert: (serialized at: 19) equals: ODBInternalReferenceCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
	
	"LargeNegativeInteger"
	
	integer := SmallInteger minVal - 1.
	object := {integer. integer}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First LargeInteger"
	self assert: (serialized at: 9) equals: ODBLargeNegativeIntegerCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
	
]

{ #category : #tests }
SoilSerializationTest >> testSerializationMessage [
	| object serialized materialized |
	object := Message selector: #+ argument: 2.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 2 0 0 0 17 18 1 43 35 1 52].
	self assert: (serialized at: 7) equals: ODBMessageCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized selector equals: object selector.
	self assert: materialized arguments equals: object arguments.
	self assert: materialized lookupClass equals: object lookupClass.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationMessageSend [
	| object serialized materialized |
	object := MessageSend receiver: 1 selector: #+ argument: 2.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 2 0 0 0 20 51 18 1 43 35 1 52].
	self assert: (serialized at: 7) equals: ODBMessageSendCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized selector equals: object selector.
	self assert: materialized arguments equals: object arguments.
	self assert: materialized receiver equals: object receiver.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationODBPersistentDictionary [
	| object serialized materialized |
	object :=  ODBPersistentDictionary new.
	object at: #key put: 1.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 83 1 18 3 107 101 121 51].
	self assert: (serialized at: 7) equals: ODBPersistentDictionaryCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationObject [
	| object serialized materialized |
	object := Object new.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 1 6 79 98 106 101 99 116 0 0 0 1 0 0 0 2 1].

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: Object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationObjectTwice [
	| object array serialized materialized |
	
	"try to serialize an object that references twice one simple object"
	object := Object new.
	array := {object . object}.

	serialized := ODBSerializer serializeToBytes: array.
	
	"First the Array"
	self assert: (serialized at: 17) equals: ODBArrayCode.
	"array of size 2"
	self assert: (serialized at: 18) equals: 2.
	"here the object ist stored (not tested)"
	"Then we get a reference to the second instance"
	self assert: (serialized at: 21) equals: ODBInternalReferenceCode.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: array first identicalTo: array second.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationOrderedCollection [
	| object serialized materialized |
	object := #(1 2 3 5) asOrderedCollection.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 81 4 51 52 53 55].
	self assert: (serialized at: 7) equals: ODBOrderedCollectionCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationProcess [
	| object serialized |
	object := Processor activeProcess.
	"we do not uet support serializing Processes"
	self should: [serialized := ODBSerializer serializeToBytes: object] raise: TestResult error
]

{ #category : #tests }
SoilSerializationTest >> testSerializationProcessSchedulerCode [
	| object serialized materialized |
	object := Processor.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 22].
	self assert: (serialized at: 7) equals: ODBProcessSchedulerCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: Processor
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationScaledDecimal [
	"ScaledDecimal is a subclass of Fraction, make sure it works"

	| object serialized materialized |
	object := 10s2.
	serialized := ODBSerializer serializeToBytes: object.
	
	"this is NOT serialized using ODBFractionCode"
	self deny: (serialized at: 7) equals: ODBFractionCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: ScaledDecimal.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationScaledDecimalTwice [
	| scaledDecimal object serialized materialized |
	
	"try to serialize an object that references twice the boxed floats"
	scaledDecimal := 10s2.
	object := {scaledDecimal . scaledDecimal}.

	serialized := ODBSerializer serializeToBytes: object.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	
	self assert: object first identicalTo: object second.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
	self assert: materialized equals: object.
]

{ #category : #'tests-hashed' }
SoilSerializationTest >> testSerializationSet [
	"Set uses the hash to find elements, this might be identity, which changes"

	| set object2 serialized materialized |

	set := Set new.
	object2 := ODBTestClass1 new.
	set add: object2.

	serialized := ODBSerializer serializeToBytes: set.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self deny: materialized anyOne identicalTo: set.
	self assert: (materialized includes:  materialized anyOne)
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSmallFloat64 [
	| float serialized materialized |
	float := 1.11.
	self assert: float class equals: SmallFloat64.
	serialized := ODBSerializer serializeToBytes: float.
	self assert: serialized equals: #[0 0 0 0 0 0 47 158 138 142 255 7 134 215 199 194 11].
	self assert: (serialized at: 7) equals: ODBSmallFloat64Code.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	
	"We changed serialization fixing https://github.com/ApptiveGrid/MoniBase/issues/22
	This checks that we can load the old serialized Floats after the change"
	
	materialized := ODBDeserializer 
		deserializeFromBytes: #[0 0 1 0 0 0 47 158 138 142 255 7 134 215 199 194 11].
	self assert: materialized identicalTo: float.
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationSmallFloat64Twice [
	| object serialized materialized |
	
	"try to serialize an object that references twice the same small floats"
	object := {1.11 . 1.11}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First Float"
	self assert: (serialized at: 9) equals: ODBSmallFloat64Code.
	"Second Float: as small floats are immediate, we do not store a reference"
	self assert: (serialized at: 20) equals: ODBSmallFloat64Code.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized first identicalTo: object first.
	self assert: materialized second identicalTo: object second.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSmallFloat64ZeroAndOne [
	| float serialized materialized |
	
	float := 0.0.
	self assert: float class equals: SmallFloat64.
	serialized := ODBSerializer serializeToBytes: float.
	self assert: serialized equals: #[0 0 0 0 0 0 47 0 0].
	self assert: (serialized at: 7) equals: ODBSmallFloat64Code.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float zero.
	
	float := 1.0.
	self assert: float class equals: SmallFloat64.
	serialized := ODBSerializer serializeToBytes: float.
	self assert: serialized equals: #[0 0 0 0 0 0 47 128 128 128 255 7 0].
	self assert: (serialized at: 7) equals: ODBSmallFloat64Code.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float one.
	
	float := -0.0.
	self assert: float class equals: SmallFloat64.
	serialized := ODBSerializer serializeToBytes: float.
	self assert: serialized equals: #[0 0 0 0 0 0 47 128 128 128 128 16 0].
	self assert: (serialized at: 7) equals: ODBSmallFloat64Code.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float negativeZero.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSmallInteger [
	| object serialized materialized |
	object := 15.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 65].
	self assert: (serialized at: 7) equals: ODBSmallPositiveIntegerBaseCode + object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: 15.

	object := -3.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 67].
	self assert: (serialized at: 7) equals: ODBMinusThreeCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: -3.
	
	self assert: ((ODBSerializer serializeToBytes: -1) at: 7) equals: ODBMinusOneCode.
	self assert: ((ODBSerializer serializeToBytes: -2) at: 7) equals: ODBMinusTwoCode.
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationSortedCollection [
	"SortedCollection is a subclass of OrderedCollection, make sure it works"

	| object serialized materialized |
	object := SortedCollection new.
	serialized := ODBSerializer serializeToBytes: object.
	
	"this is NOT serialized using ODBOrderedCollectionCode"
	self deny: (serialized at: 7) equals: ODBOrderedCollectionCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationString [ 
	| string serialized materialized |
	
	"empty String"
	
	string := ''.
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals:#[0 0 1 0 0 0 70].
	self assert: (serialized at: 7) equals: ODBSmallStringBaseCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: ''.
	
	"Small String with size 1"
	
	string := 'h'.
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals:#[0 0 1 0 0 0 71 104].
	self assert: (serialized at: 7) equals: ODBSmallStringBaseCode + string size.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: 'h'.
	
	"Small String with size < 10"
	
	string := 'hello'.
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals: #[0 0 1 0 0 0 75 104 101 108 108 111].
	self assert: (serialized at: 7) equals: ODBSmallStringBaseCode + string size.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: 'hello'.

	"Larger (all other) Strings"
	
	string := 'helloWithMoreCharacters'.
	serialized := ODBSerializer serializeToBytes: string.
	self 
		assert: serialized
		equals: #[0 0 1 0 0 0 34 23 104 101 108 108 111 87 105 116 104 77 111 114 101 67 104 97 114 97 99 116 101 114 115].
	self assert: (serialized at: 7) equals: ODBStringCode.
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: string
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationStringTwice [
	
	| object serialized materialized |
	
	"try to serialize an object that references twice the string"
	object := {'h' . 'h'}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First String"
	self assert: (serialized at: 9) equals: ODBSmallStringBaseCode + 1.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 11) equals: ODBInternalReferenceCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	

	object := {'hello' . 'hello'}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First String"
	self assert: (serialized at: 9) equals: ODBSmallStringBaseCode + 5.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 15) equals: ODBInternalReferenceCode.
	

	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	

	object := {'helloWithMoreCharacters' . 'helloWithMoreCharacters'}.

	serialized := ODBSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 7) equals: ODBArrayCode.
	"First String"
	self assert: (serialized at: 9) equals: ODBStringCode.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 34) equals: ODBInternalReferenceCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSymbol [
	| object serialized materialized |
	object := #someSelector.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 18 12 115 111 109 101 83 101 108 101 99 116 111 114].
	self assert: (serialized at: 7) equals: ODBSymbolCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: #someSelector
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSystemDictionary [
	| object serialized materialized |
	object := Smalltalk globals.
	object at: #Object put: Object.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 19].
	self assert: (serialized at: 7) equals: ODBSystemDictionaryCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assertCollection: materialized hasSameElements: Smalltalk globals
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationTTLAssociation [
	"TTLAssociation is a subclass of Association, make sure it works"

	| object serialized materialized |
	object := TTLAssociation key: #t value: 1.
	serialized := ODBSerializer serializeToBytes: object.
	
	"this is NOT serialized using ODBAssociationCode"
	self deny: (serialized at: 7) equals: ODBAssociationCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized class equals: object class.
	self assert: materialized equals: object

]

{ #category : #tests }
SoilSerializationTest >> testSerializationTime [
	| object serialized materialized |
	object := Time midnight.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 33 0].
	self assert: (serialized at: 7) equals: ODBTimeCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationTrue [
	| object serialized materialized |
	object := true.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[7].
	self assert: (serialized at: 1) equals: TypeCodeTrue.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized.
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationUUID [
	"UUID is a subclass of ByteArray, make sure it works"

	| object serialized materialized |
	object := UUID fromString: 'e42b03f8-3e9a-0d00-862e-bf1701b4bbce'.
	serialized := ODBSerializer serializeToBytes: object.
	
	"this is NOT serialized using ODBByteArrayCode"
	self deny: (serialized at: 7) equals: ODBByteArrayCode.
	
	self 
		assert: serialized
		equals: #[0 1 4 85 85 73 68 1 1 0 1 0 0 0 2 1 16 228 43 3 248 62 154 13 0 134 46 191 23 1 180 187 206].

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationUndefindedObject [
	| object serialized materialized |
	object := nil.
	serialized := ODBSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 0 0 0 0 14].
	self assert: (serialized at: 7) equals: ODBUndefinedObjectCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: nil
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationVariableLayout [
	| object serialized materialized |
	"All Immediate classes are specially encoded, to have a test for every layout, use Character here"
	object := $a.
	
	self assert: object class classLayout class equals: ImmediateLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: Character.
	self assert: materialized class classLayout class equals: ImmediateLayout.
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationWeakArray [
	"WeakArray is a subclass of Array, make sure it works"

	| object serialized materialized |
	object := WeakArray new.
	serialized := ODBSerializer serializeToBytes: object.
	
	"this is NOT serialized using ODBOrderedCollectionCode"
	self deny: (serialized at: 7) equals: ODBArrayCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationWeakLayout [
	| object serialized materialized |
	"We use WeakArray as an exampe of a class with a WeakLayout"
	object := WeakArray with: 'String'.
	
	self assert: object class classLayout class equals: WeakLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: WeakArray.
	self assert: materialized class classLayout class equals: WeakLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationWideStringUTF16 [

	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	ODBEncodingStream characterEncoding: #utf16.
	
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals: #[0 0 1 0 0 0 36 8 246 0 246 3 1 85 1 17].
	self assert: (serialized at: 7) equals: ODBWideStringCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: string.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationWideStringUTF32 [

	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	ODBEncodingStream characterEncoding: #utf32.
	
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals: #[0 0 1 0 0 0 36 16 0 0 246 0 0 0 246 3 0 0 1 85 0 0 1 17].
	self assert: (serialized at: 7) equals: ODBWideStringCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: string.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationWideStringUTF8 [
	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	ODBEncodingStream characterEncoding: #utf8.
	
	serialized := ODBSerializer serializeToBytes: string.
	self assert: serialized equals: #[0 0 1 0 0 0 36 10 239 152 128 239 152 131 197 149 196 145].
	self assert: (serialized at: 7) equals: ODBWideStringCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: string.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationWideSymbol [
	| symbol serialized materialized |
	symbol := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	symbol := symbol asSymbol.
	self assert: symbol isWideString.
	
	ODBEncodingStream characterEncoding: #utf8.
	
	serialized := ODBSerializer serializeToBytes: symbol.
	self assert: serialized equals: #[0 0 0 0 0 0 48 10 239 152 128 239 152 131 197 149 196 145].
	self assert: (serialized at: 7) equals: ODBWideSymbolCode.
	
	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: symbol
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationWordLayout [
	| object serialized materialized |
	"We use IntegerArray as an exampe of a class with a WordLayout but not specially encoded"
	object := IntegerArray new: 5 withAll: 2.
	
	self assert: object class classLayout class equals: WordLayout.
	serialized := ODBSerializer serializeToBytes: object.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: IntegerArray.
	self assert: materialized class classLayout class equals: WordLayout.
]
