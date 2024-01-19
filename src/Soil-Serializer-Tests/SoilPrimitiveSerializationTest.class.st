Class {
	#name : #SoilPrimitiveSerializationTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : 'Soil-Serializer-Tests'
}

{ #category : #'instance creation' }
SoilPrimitiveSerializationTest >> newSerializer [ 
	^ Soil inMemory newSerializer
]

{ #category : #helpers }
SoilPrimitiveSerializationTest >> restoreLocalTimeZoneAfter: aBlock [

	| realTimeZone |
	realTimeZone := DateAndTime localTimeZone.
	aBlock ensure: [ DateAndTime localTimeZone: realTimeZone ].
]

{ #category : #running }
SoilPrimitiveSerializationTest >> setUp [
	super setUp.
	SoilTypeCodes initialize
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationArray [
	| object serialized materialized |
	object := #(1 2 3 5).
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[17 4 5 1 5 2 5 3 5 5].
	self assert: (serialized at: 1) equals: TypeCodeArray.

	materialized := SoilMaterializer materializeFromBytes: serialized. 
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationAssociation [
	| object serialized materialized |
	object := 1 -> 2.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[24 5 1 5 2].
	self assert: (serialized at: 1) equals: TypeCodeAssociation.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationBlockClosure [
	| object serialized  |
	object := [].
	"we do not uet support serializing closures"
	self should: [serialized := SoilSerializer serializeToBytes: object] raise: TestResult error
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationBoxedFloat64 [
	| float serialized materialized |
	float := 2.45227231256843e-45.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[7 128 128 176 181 3 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: 2.45227231256843e-45
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationBoxedFloat64Infinity [
	| float serialized materialized |
	float := Float infinity.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[7 128 128 192 255 7 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: float.
	
	float := Float negativeInfinity.
	self assert: float class equals: BoxedFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self 
		assert: serialized
		equals: #[7 128 128 192 255 15 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: BoxedFloat64.
	self assert: materialized equals: float
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationBoxedFloat64Twice [
	| float object serialized materialized |
	
	"try to serialize an object that references twice the boxed floats"
	float := 2.45227231256843e-45.
	object := {float . float}.
	
	self deny: float isImmediateObject.

	serialized := SoilSerializer serializeToBytes: object.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First Float"
	self assert: (serialized at: 3) equals: TypeCodeFloat.
	"Second Float: as this is a real object, we see reference to it"
	self assert: (serialized at: 10) equals: TypeCodeInternalReference.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationByteArray [
	| object serialized materialized |
	object := #[1 2 3 5].
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[19 4 1 2 3 5].
	self assert: (serialized at: 1) equals: TypeCodeByteArray.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationByteCharacter [
	| object serialized materialized |
	object := $a.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[10 97].
	self assert: (serialized at: 1) equals: TypeCodeCharacter.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationByteCharacterTwice [
	| object character serialized materialized |
	character := $a.
	object := {character. character}.

	serialized := SoilSerializer  serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First Character"
	self assert: (serialized at: 3) equals: TypeCodeCharacter.
	"Second Character, they are immediate objects, so we do store them directly"
	self assert: (serialized at: 5) equals: TypeCodeCharacter.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationCharacter [
	| object serialized materialized |
	object := 16rF600 asCharacter.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[10 128 236 3].
	self assert: (serialized at: 1) equals: TypeCodeCharacter.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationCharacterTwice [
	| object character serialized materialized |

	character := 16rF600 asCharacter.
	object := {character. character}.

	serialized := SoilSerializer serializeToBytes: object.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.

]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationClass [
	| object serialized materialized |
	object := Point.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[49 5 80 111 105 110 116].
	self assert: (serialized at: 1) equals: TypeCodeClass.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized  equals: Point.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationDate [
	| object serialized materialized |
	object := Date fromDays: 10.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[27 5 10 5 0].
	self assert: (serialized at: 1) equals: TypeCodeDate.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationDateNegative [
	| object serialized materialized |
	object := (DateAndTime year: 1900 month: 1 day: 1 hour: 0 minute: 0 second: 0 offset: 0 hours) asDate.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[27 6 237 2 5 0].
	self assert: (serialized at: 1) equals: TypeCodeDate.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationDateWithLocalTimeZone [
	| utc est bst object utc14plus utc545plus utc12minus utc330minus serialized materialized |
	utc := TimeZone abbreviated: 'UTC'.
	est := TimeZone abbreviated: 'EST'.
	bst := TimeZone abbreviated: 'BST'.
	utc12minus := TimeZone offset: -12 hours name: 'Baker Island Time' abbreviation: 'BIT'.
	utc14plus := TimeZone offset: 14 hours name: 'Line Islands Time' abbreviation: 'LINT'.
	utc330minus := TimeZone offset: (3 * 60 + 30) minutes negated name: 'Newfoundland Time' abbreviation: 'NT'.
	utc545plus := TimeZone offset: (5 * 60 + 45) minutes name: 'Nepal Time' abbreviation: 'NPT'.
	{
		{ utc. utc }.
		{ utc. est }. { est. utc }.
		{ utc. bst }. { bst. utc }.
		{ est. bst }. { bst. est }.
		{ utc12minus. utc14plus }. { utc14plus. utc12minus }.
		{ utc. utc330minus }. { utc330minus. utc }.
		{ utc. utc545plus }. { utc545plus. utc }.
	} do: [ :eachPair |
		self useTimeZoneInstance: eachPair first during: [
			object := Date year: 2022 month: 10 day: 31.
			serialized := SoilSerializer serializeToBytes: object.
			"self assert: serialized equals: eachCase value."
			self assert: (serialized at: 1) equals: TypeCodeDate ].

		self useTimeZoneInstance: eachPair second during: [
			materialized := SoilMaterializer materializeFromBytes: serialized.
			self assert: materialized equals: object ] ]
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationDateWithNegativeOffset [
	| object serialized materialized |
	object := (Date fromDays: 10) offset: -5 hours.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[27 5 9 6 172 2].
	self assert: (serialized at: 1) equals: TypeCodeDate.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: (materialized equals: object)
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationDictionary [
	| object serialized materialized |
	object := { 1->2 . 3->4 } asDictionary.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[25 2 5 1 5 2 5 3 5 4].
	self assert: (serialized at: 1) equals: TypeCodeDictionary.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilPrimitiveSerializationTest >> testSerializationEphemeronLayout [
	"Emphemeron classes are not yet used (no example in Pharo11), thus we do not support them yet"
	self flag: #TODO
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationFalse [
	| object serialized materialized |
	"Check false"
	object := false.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[4].
	self assert: (serialized at: 1) equals: TypeCodeFalse.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self deny: materialized
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationFraction [
	| object serialized materialized |
	object := 1/2.
	self assert: object class equals: Fraction.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[8 1 2].
	self assert: (serialized at: 1) equals: TypeCodeFraction.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationFractionTwice [
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
SoilPrimitiveSerializationTest >> testSerializationIdentityDictionary [
	| object serialized materialized |
	object := IdentityDictionary newFrom: { #test->2 . #now->4 }.
	serialized := SoilSerializer serializeToBytes: object.
	
	 self assert: (
 			serialized = 
 			"the order of association in the dict is different between Pharo10 and Pharo11"
 			#[26 2 20 4 116 101 115 116 5 2 20 3 110 111 119 5 4 ]
 		or: [ 
 			serialized = 
 			#[26 2 20 3 110 111 119 5 4 20 4 116 101 115 116 5 2]]).
		
	self assert: (serialized at: 1) equals: TypeCodeIdentityDictionary.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: IdentityDictionary.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilPrimitiveSerializationTest >> testSerializationImmediateLayout [
	| object serialized materialized |
	"All Immediate classes are specially encoded, to have a test for every layout, use Character here"
	object := $a.
	
	self assert: object class classLayout class equals: ImmediateLayout.
	serialized := SoilSerializer serializeToBytes: object.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: Character.
	self assert: materialized class classLayout class equals: ImmediateLayout.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationLargeInteger [
	| object serialized materialized |
	
	"Integers are small if they are in between -3 and 16"
	"The test in addition tests LargeIntegers, but for the databse, they are just the same"
	
	object := 17.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[5 17].
	self assert: (serialized at: 1) equals: TypeCodePositiveInteger.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	object := -4.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[6 4].
	self assert: (serialized at: 1) equals: TypeCodeNegativeInteger .

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	
	object := SmallInteger maxVal + 1.
	serialized := SoilSerializer  serializeToBytes: object.
	self assert: serialized equals: #[5 128 128 128 128 128 128 128 128 16].
	self assert: (serialized at: 1) equals: TypeCodePositiveInteger.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	
	"Negative"
	object := SmallInteger minVal - 1.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[6 129 128 128 128 128 128 128 128 16].
		self assert: (serialized at: 1) equals: TypeCodeNegativeInteger.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationLargeIntegerTwice [

	| object integer serialized materialized |
	
	"LargeInteger"
	
	integer := SmallInteger maxVal + 1.
	object := {integer. integer}.

	serialized := SoilSerializer serializeToBytes: object.
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First LargeInteger"
	self assert: (serialized at: 3) equals: TypeCodePositiveInteger.
	"Second LargeInteger, reference to the first"
	self assert: (serialized at: 13) equals: TypeCodeInternalReference.
	

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
	
	"LargeNegativeInteger"
	
	integer := SmallInteger minVal - 1.
	object := {integer. integer}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First LargeInteger"
	self assert: (serialized at: 3) equals: TypeCodeNegativeInteger.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: object first identicalTo: object second.
	self assert: materialized equals: object.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
	
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationODBPersistentDictionary [
	| object serialized materialized |
	self flag: #todo. 
	"come up with a special class for this"
	
	"object :=  ODBPersistentDictionary new.
	object at: #key put: 1.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[0 0 1 0 0 0 83 1 18 3 107 101 121 51].
	self assert: (serialized at: 7) equals: ODBPersistentDictionaryCode.

	materialized := ODBDeserializer deserializeFromBytes: serialized.
	self assert: materialized equals: object"
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationOrderedCollection [
	| object serialized materialized |
	object := #(1 2 3 5) asOrderedCollection.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[18 4 5 1 5 2 5 3 5 5].
	self assert: (serialized at: 1) equals: TypeCodeOrderedCollection.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationProcess [
	| object serialized |
	object := Processor activeProcess.
	"we do not uet support serializing Processes"
	self should: [serialized := SoilSerializer serializeToBytes: object] raise: TestResult error
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationProcessSchedulerCode [
	| object serialized materialized |
	object := Processor.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[53].
	self assert: (serialized at: 1) equals: TypeCodeProcessScheduler.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: Processor
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationScaledDecimal [
	"ScaledDecimal is a subclass of Fraction, make sure it works"

	| object serialized materialized |
	object := 10s2.
	serialized := SoilSerializer serializeToBytes: object.
	
	self assert: (serialized at: 1) equals: TypeCodeScaledDecimal.
	self assert: serialized equals: #[9 5 10 1 2].
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: ScaledDecimal.
	self assert: materialized equals: object
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationScaledDecimalTwice [
	| scaledDecimal object serialized materialized |
	
	"try to serialize an object that references twice the boxed floats"
	scaledDecimal := 10s2.
	object := {scaledDecimal . scaledDecimal}.

	serialized := SoilSerializer serializeToBytes: object.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	
	self assert: object first identicalTo: object second.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationSmallFloat64 [
	| float serialized materialized |
	float := 1.11.
	self assert: float class equals: SmallFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self assert: serialized equals: #[7 143 133 199 255 3 195 235 163 225 5].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationSmallFloat64Twice [
	| object serialized materialized |
	
	"try to serialize an object that references twice the same small floats"
	object := {1.11 . 1.11}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First Float"
	self assert: (serialized at: 3) equals: TypeCodeFloat.
	"Second Float: as small floats are immediate, we do not store a reference"
	self assert: (serialized at: 14) equals: TypeCodeFloat.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized first identicalTo: object first.
	self assert: materialized second identicalTo: object second.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationSmallFloat64ZeroAndOne [
	| float serialized materialized |
	
	float := 0.0.
	self assert: float class equals: SmallFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self assert: serialized equals: #[7 0 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float zero.
	
	float := 1.0.
	self assert: float class equals: SmallFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self assert: serialized equals: #[7 128 128 192 255 3 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float one.
	
	float := -0.0.
	self assert: float class equals: SmallFloat64.
	serialized := SoilSerializer serializeToBytes: float.
	self assert: serialized equals: #[7 128 128 128 128 8 0].
	self assert: (serialized at: 1) equals: TypeCodeFloat.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: SmallFloat64.
	self assert: materialized identicalTo: float.
	self assert: materialized identicalTo: Float negativeZero.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationString [ 
	| string serialized materialized |
	
	"empty String"
	
	string := ''.
	serialized := SoilSerializer serializeToBytes: string.
	self assert: serialized equals: #[21 0].
	self assert: (serialized at: 1) equals: TypeCodeString.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: ''.
	
	"Small String"
	string := 'a'.
	serialized := SoilSerializer serializeToBytes: string.
	self assert: serialized equals: #[21 1 97].
	self assert: (serialized at: 1) equals: TypeCodeString.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: 'a'.
	
	"Larger (all other) Strings"
	
	string := 'helloWithMoreCharacters'.
	serialized := SoilSerializer serializeToBytes: string.
	self 
		assert: serialized
		equals: #[21 23 104 101 108 108 111 87 105 116 104 77 111 114 101 67 104 97 114 97 99 116 101 114 115].
	self assert: (serialized at: 1) equals: TypeCodeString.
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: string
]

{ #category : #'tests-twice' }
SoilPrimitiveSerializationTest >> testSerializationStringTwice [
	
	| object serialized materialized |
	
	"try to serialize an object that references twice the string"
	object := {'h' . 'h'}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First String"
	self assert: (serialized at: 3) equals: TypeCodeString.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 6) equals: TypeCodeInternalReference.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	

	object := {'hello' . 'hello'}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First String"
	self assert: (serialized at: 3) equals: TypeCodeString.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 10) equals: TypeCodeInternalReference.
	

	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	

	object := {'helloWithMoreCharacters' . 'helloWithMoreCharacters'}.

	serialized := SoilSerializer serializeToBytes: object.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"First String"
	self assert: (serialized at: 3) equals: TypeCodeString.
	"Second String is stored as an internal reference"
	self assert: (serialized at: 28) equals: TypeCodeInternalReference.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationSymbol [
	| object serialized materialized |
	object := #someSelector.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[20 12 115 111 109 101 83 101 108 101 99 116 111 114].
	self assert: (serialized at: 1) equals: TypeCodeSymbol.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: #someSelector
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationSystemDictionary [
	| object serialized materialized |
	object := Smalltalk globals.
	object at: #Object put: Object.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[ 52 ].
	self assert: (serialized at: 1) equals: TypeCodeSystemDictionary.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assertCollection: materialized hasSameElements: Smalltalk globals
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationTime [
	| object serialized materialized |
	object := Time midnight.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[28 0].
	self assert: (serialized at: 1) equals: TypeCodeTime.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationTrue [
	| object serialized materialized |
	object := true.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[3].
	self assert: (serialized at: 1) equals: TypeCodeTrue.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationUndefindedObject [
	| object serialized materialized |
	object := nil.
	serialized := SoilSerializer serializeToBytes: object.
	self assert: serialized equals: #[2].
	self assert: (serialized at: 1) equals: TypeCodeUndefined.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: nil
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationWideStringUTF16 [

	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	Soil characterEncoding: #utf16.

	serialized := SoilSerializer serializeToBytes: string.
	self assert: serialized equals: #[23 8 246 0 246 3 1 85 1 17].
	self assert: (serialized at: 1) equals: TypeCodeWideString.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: string.
	
	"set the encoding back to the default"
	Soil characterEncoding: #utf8
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationWideStringUTF32 [

	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	Soil characterEncoding: #utf32.
		
	serialized := SoilSerializer serializeToBytes: string.
	self assert: serialized equals: #[23 16 0 0 246 0 0 0 246 3 0 0 1 85 0 0 1 17].
	self assert: (serialized at: 1) equals: TypeCodeWideString.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: string.
	
	"set the encoding back to the default"
	Soil characterEncoding: #utf8
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationWideStringUTF8 [
	| string serialized materialized |
	string := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	self assert: string isWideString.
	Soil characterEncoding: #utf8.
	
	serialized := SoilSerializer serializeToBytes: string.
	self assert: serialized equals: #[23 10 239 152 128 239 152 131 197 149 196 145].
	self assert: (serialized at: 1) equals: TypeCodeWideString.

	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: string.
]

{ #category : #tests }
SoilPrimitiveSerializationTest >> testSerializationWideSymbol [
	| symbol serialized materialized |
	symbol := String
		with: 16rF600 asCharacter
		with: 16rF603 asCharacter
		with: 16r0155 asCharacter
		with: 16r0111 asCharacter.
	symbol := symbol asSymbol.
	self assert: symbol isWideString.
	
	serialized := SoilSerializer serializeToBytes: symbol.
	self assert: serialized equals: #[22 10 239 152 128 239 152 131 197 149 196 145].
	self assert: (serialized at: 1) equals: TypeCodeWideSymbol.
	
	materialized := SoilMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: symbol
]

{ #category : #helpers }
SoilPrimitiveSerializationTest >> useTimeZoneInstance: aTimeZone during: aBlock [

  self restoreLocalTimeZoneAfter: [ 
    DateAndTime localTimeZone: aTimeZone. 
    aBlock cull: aTimeZone ].
]
