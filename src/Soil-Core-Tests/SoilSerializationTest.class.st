Class {
	#name : #SoilSerializationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'transaction'
	],
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'instance creation' }
SoilSerializationTest >> newMaterializer [
	^ transaction newMaterializer
]

{ #category : #'instance creation' }
SoilSerializationTest >> newSerializer [ 
	^ transaction newSerializer
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> serializeToBytes: object [
	| bytes |
	bytes := self newSerializer serializeToBytes: object.
	transaction commit.
	transaction := soil newTransaction.
	^ bytes
]

{ #category : #running }
SoilSerializationTest >> setUp [
	super setUp.
	SoilTypeCodes initialize.
	soil := (Soil path: 'soil-tests') destroy; initializeFilesystem.
	transaction := soil newTransaction
]

{ #category : #tests }
SoilSerializationTest >> testBasicSerialize [
	| bytes |
	bytes := self serializeToBytes: SOTestClusterRoot new.
	self assert: bytes equals: #[1 3 2]
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationByteLayout [
	| object serialized materialized |
	"We use SocketAddress as an exampe of a class with a ByteLayout but not specially encoded"
	object := #[127 0 0 1] asSocketAddress.
	
	self assert: object class classLayout class equals: ByteLayout.
	serialized := self newSerializer serializeToBytes: object.
	transaction commit.
	transaction := soil newTransaction.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: SocketAddress.
	self assert: materialized class classLayout class equals: ByteLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationCompiledMethodLayout [

	| object serialized materialized |
	self skip.
	"We use CompiledMethod as an exampe of a class with a CompiledMethodLayout"
	object := (OrderedCollection >> #do:) copy.

	self
		assert: object class classLayout class
		equals: CompiledMethodLayout.
	serialized := self serializeToBytes: object.
	materialized := self newMaterializer materializeFromBytes: serialized.

	(SystemVersion current major == 11)
		ifTrue: [ self assert: materialized bytecodes equals: object bytecodes. ]
		ifFalse: [ self assert: materialized bytecode equals: object bytecode. ].
	
	self assert: materialized literals equals: object literals.
	self assert: materialized equals: object.
	self
		assert: materialized class classLayout class
		equals: CompiledMethodLayout
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationCompiledMethodLayoutCompiledBlock [
	| object serialized materialized |
 	"This tests CompiledBlock. we use a clean block for now"
 	object := [1+2 "clean block"] compiledBlock.

 	self assert: object class classLayout class equals: CompiledMethodLayout.
 	serialized := self serializeToBytes: object.

 	materialized := self newMaterializer materializeFromBytes: serialized.

 	"for #= we need equal outercode to be the same, too"
 	(SystemVersion current major == 11)
		ifTrue: [ self assert: materialized bytecodes equals: object bytecodes. ]
		ifFalse: [ self assert: materialized bytecode equals: object bytecode. ].
 	self assert: materialized literals equals: object literals.
 	self assert: materialized class classLayout class equals: CompiledMethodLayout
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationDoubleByteLayout [
	| object serialized materialized |
	"We use DoubleByteArray as an exampe of a class with a DoubleByteLayout but not specially encoded"
	object := DoubleByteArray newFrom: #(10 20 30 40).
	
	self assert: object class classLayout class equals: DoubleByteLayout.
	serialized := self serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: DoubleByteArray.
	self assert: materialized class classLayout class equals: DoubleByteLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationDoubleWordLayout [
	| object serialized materialized |
	"We use DoubleWordArray as an exampe of a class with a DoubleWordLayout but not specially encoded"
	object := DoubleWordArray newFrom: #(10 20 30 40).
	
	self assert: object class classLayout class equals: DoubleWordLayout.
	serialized := self serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: DoubleWordArray.
	self assert: materialized class classLayout class equals: DoubleWordLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationFixedLayout [
	| object serialized materialized |
	"We use Point as an exampe of a class with a FixedLayout but not specially encoded"
	object := 4@3.
	
	self assert: object class classLayout class equals: FixedLayout.
	serialized := self serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: Point.
	self assert: materialized class classLayout class equals: FixedLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationObject [
	| object serialized materialized |
	object := Object new.
	serialized := self serializeToBytes: object.
	self assert: serialized equals: #[1 3].
	self assert: (serialized at: 1) equals: TypeCodeObject.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: Object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationObjectTwice [
	| object array serialized materialized |
	
	"try to serialize an object that references twice one simple object"
	object := Object new.
	array := {object . object}.

	serialized := self serializeToBytes: array.
	
	"First the Array"
	self assert: (serialized at: 1) equals: TypeCodeArray.
	"array of size 2"
	self assert: (serialized at: 2) equals: 2.
	"here the object ist stored (not tested)"
	"Then we get a reference to the second instance"
	self assert: (serialized at: 5) equals: TypeCodeInternalReference.
	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: array first identicalTo: array second.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
]

{ #category : #'tests-hashed' }
SoilSerializationTest >> testSerializationSet [
	"Set uses the hash to find elements, this might be identity, which changes"

	| set object2 serialized materialized |
	set := Set new.
	object2 := SOTestClass1 new.
	set add: object2.

	serialized := self serializeToBytes: set.
	materialized := self newMaterializer materializeFromBytes: serialized.
	"rehashing fixes the Set but how to do?"
	"materialized rehash."
	self deny: materialized anyOne identicalTo: set.
	self assert: (materialized includes:  materialized anyOne)
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationSortedCollection [
	"SortedCollection is a subclass of OrderedCollection, make sure it works"

	| object serialized materialized |
	object := SortedCollection new.
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeOrderedCollection"
	self deny: (serialized at: 1) equals: TypeCodeOrderedCollection.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationTTLAssociation [
	"TTLAssociation is a subclass of Association, make sure it works"

	| object serialized materialized |
	object := TTLAssociation key: #t value: 1.
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeAssociation"
	self deny: (serialized at: 1) equals: TypeCodeAssociation.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized class equals: object class.
	self assert: materialized equals: object

]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationUUID [
	"UUID is a subclass of ByteArray, make sure it works"

	| object serialized materialized |
	object := UUID fromString: 'e42b03f8-3e9a-0d00-862e-bf1701b4bbce'.
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeByteArray"
	self deny: (serialized at: 1) equals: TypeCodeByteArray.
	
	self 
		assert: serialized
		equals:  #[1 3 16 228 43 3 248 62 154 13 0 134 46 191 23 1 180 187 206].

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationVariableLayout [
	| object serialized materialized |
	"All Immediate classes are specially encoded, to have a test for every layout"
	object := Path root.
	
	self assert: object class classLayout class equals: VariableLayout.
	serialized := self  serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: AbsolutePath.
	self assert: materialized class classLayout class equals: VariableLayout.
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationWeakArray [
	"WeakArray is a subclass of Array, make sure it works"

	| object serialized materialized |
	object := WeakArray new.
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeArray"
	self deny: (serialized at: 1) equals: TypeCodeArray.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationWeakLayout [
	| object serialized materialized |
	"We use WeakArray as an exampe of a class with a WeakLayout"
	object := WeakArray with: 'String'.
	
	self assert: object class classLayout class equals: WeakLayout.
	serialized := self serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: WeakArray.
	self assert: materialized class classLayout class equals: WeakLayout.
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationWordLayout [
	| object serialized materialized |
	"We use IntegerArray as an exampe of a class with a WordLayout but not specially encoded"
	object := IntegerArray new: 5 withAll: 2.
	
	self assert: object class classLayout class equals: WordLayout.
	serialized := self serializeToBytes: object.

	materialized := self newMaterializer materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: IntegerArray.
	self assert: materialized class classLayout class equals: WordLayout.
]
