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
	#category : #'Soil-Serializer-Tests'
}

{ #category : #'tests-layouts' }
SoilSerializationTest >> materializeFromBytes: aByteArray [
	^ (transaction newPersistentClusterVersion 
		readFrom: aByteArray readStream)
		materializeObject  object
]

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
	bytes := transaction newClusterVersion
		version: 1;
		object: object;
		serialize.
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

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationByteLayout [
	| object serialized materialized |
	"We use SocketAddress as an exampe of a class with a ByteLayout but not specially encoded"
	object := #[127 0 0 1] asSocketAddress.
	
	self assert: object class classLayout class equals: ByteLayout.
	serialized := self serializeToBytes: object.
	transaction commit.
	transaction := soil newTransaction.

	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: SocketAddress.
	self assert: materialized class classLayout class equals: ByteLayout.
]

{ #category : #'test-blocks' }
SoilSerializationTest >> testSerializationCleanBlockClosure [
	<compilerOptions: #(+ optionCleanBlockClosure)>
	| object serialized  materialized |
	(SystemVersion current major >= 11) ifFalse: [ self skip ].
	object := [1+2].
	
	serialized := self serializeToBytes: object.
	materialized := self materializeFromBytes: serialized.
	self assert: materialized class equals: CleanBlockClosure.
	"and we can execute it!"
	self assert: materialized value equals: 3
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationCompiledMethodLayout [

	| object serialized materialized |
	"We use CompiledMethod as an exampe of a class with a CompiledMethodLayout"
	(SystemVersion current major >= 11) ifFalse: [ self skip ].
	object := (OrderedCollection >> #do:) copy.

	self
		assert: object class classLayout class
		equals: CompiledMethodLayout.
	serialized := self serializeToBytes: object.
	materialized := self materializeFromBytes: serialized.

	self assert: materialized bytecodes equals: object bytecodes.
	self assert: materialized literals equals: object literals.
	self assert: materialized equals: object.
	self
		assert: materialized class classLayout class
		equals: CompiledMethodLayout
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationCompiledMethodLayoutCompiledBlock [
	| object serialized materialized |
	(SystemVersion current major >= 11) ifFalse: [ self skip ].
 	"This tests CompiledBlock. we use a clean block for now"
 	object := [1+2 "clean block"] compiledBlock.

 	self assert: object class classLayout class equals: CompiledMethodLayout.
 	serialized := self serializeToBytes: object.

 	materialized := self materializeFromBytes: serialized.

 	"for #= we need equal outercode to be the same, too"
	self assert: materialized bytecodes equals: object bytecodes.
 	self assert: materialized literals equals: object literals.
 	self assert: materialized class classLayout class equals: CompiledMethodLayout
]

{ #category : #'test-blocks' }
SoilSerializationTest >> testSerializationConstantBlockClosure [
	| object serialized  materialized |
	(SystemVersion current major >= 11) ifFalse: [ self skip ].
	object := [1].
	
	serialized := self serializeToBytes: object.
	materialized := self materializeFromBytes: serialized.
	self assert: materialized class name equals: #ConstantBlockClosure.
	"and we can execute it!"
	self assert: materialized value equals: 1.
	"but otherCode is nil, we need to improve that somehow"
	self assert: materialized outerCode isNil
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationDoubleByteLayout [
	| object serialized materialized |
	"We use DoubleByteArray as an exampe of a class with a DoubleByteLayout but not specially encoded"
	object := DoubleByteArray newFrom: #(10 20 30 40).
	
	self assert: object class classLayout class equals: DoubleByteLayout.
	serialized := self serializeToBytes: object.

	materialized := self materializeFromBytes: serialized.
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

	materialized := self materializeFromBytes: serialized.
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

	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: Point.
	self assert: materialized class classLayout class equals: FixedLayout.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationObject [
	| object serialized materialized |
	object := Object new.
	serialized := self serializeToBytes: object.
	self assert: serialized equals:  #[1 0 0 3 1 3 1].
	self assert: (serialized at: 5) equals: TypeCodeObject.

	materialized := self materializeFromBytes: serialized.
	self assert: materialized class equals: Object
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationObjectEqualTwice [
	| object array serialized materialized |

	"try to serialize an object that references two objects that are equal"
	object := 'test'.
	array := {object. object copy}.

	serialized := self serializeToBytes: array.

	"First the Array"
	self assert: (serialized at: 5) equals: TypeCodeArray.
	"array of size 2"
	self assert: (serialized at: 6) equals: 2.
	materialized := self materializeFromBytes: serialized.
	self deny: array first identicalTo: array second.
	self assert:  array first equals: array second.
	"we do store the two strings correctly"
	self assert:  materialized first equals: object.
	self assert:  materialized first equals: materialized second.
	"non-identity is preserved"
	self deny: materialized first identicalTo: materialized second
]

{ #category : #'tests-twice' }
SoilSerializationTest >> testSerializationObjectTwice [
	| object array serialized materialized |
	
	"try to serialize an object that references twice one simple object"
	object := Object new.
	array := {object . object}.

	serialized := self serializeToBytes: array.
	
	"First the Array"
	self assert: (serialized at: 5) equals: TypeCodeArray.
	"array of size 2"
	self assert: (serialized at: 6) equals: 2.
	"here the object ist stored (not tested)"
	"Then we get a reference to the second instance"
	self assert: (serialized at: 10) equals: TypeCodeInternalReference.
	materialized := self materializeFromBytes: serialized.
	self assert: array first identicalTo: array second.
	"identity is preserved"
	self assert: materialized first identicalTo: materialized second.
]

{ #category : #tests }
SoilSerializationTest >> testSerializationObjectWithTransient [
	| object serialized materialized |
	object := SoilTestClassWithTransient new.
	object one: 1; two: 2; three: 3.
	serialized := self serializeToBytes: object.
	materialized := self materializeFromBytes: serialized.
	self assert: materialized one equals: 1.
	self assert: materialized two isNil.
	self assert: materialized three equals: 3
]

{ #category : #'tests-hashed' }
SoilSerializationTest >> testSerializationSet [
	"Set uses the hash to find elements, this might be identity, which changes"

	| set object2 serialized materialized |
	set := Set new.
	object2 := SoilTestClass1 new.
	set add: object2.

	serialized := self serializeToBytes: set.
	materialized := self  materializeFromBytes: serialized.
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

	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #tests }
SoilSerializationTest >> testSerializationSortedCollectionWithSortBlock [
	"SortedCollection ixs a subclass of OrderedCollection, make sure it works"
	<compilerOptions: #(+ optionCleanBlockClosure)>

	| object serialized materialized |
	(SystemVersion current major == 11) ifFalse: [ self skip ].
	object := SortedCollection new sortBlock: [ :a :b | a > b ].
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeOrderedCollection"
	self deny: (serialized at: 1) equals: TypeCodeOrderedCollection.

	materialized := self materializeFromBytes: serialized.
	self assert: materialized class equals: object class.
	"not yet equal as the blocks have wrong outerCode, but ok for execution"
	self assert: materialized sortBlock compiledBlock bytecodes equals: object sortBlock compiledBlock bytecodes.	
]

{ #category : #'tests-encoded-subclasses' }
SoilSerializationTest >> testSerializationTTLAssociation [
	"TTLAssociation is a subclass of Association, make sure it works"

	| object serialized materialized |
	object := TTLAssociation key: #t value: 1.
	serialized := self serializeToBytes: object.
	
	"this is NOT serialized using TypeCodeAssociation"
	self deny: (serialized at: 1) equals: TypeCodeAssociation.

	materialized := self materializeFromBytes: serialized.
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
		equals:    #[1 0 0 20 1 3 1 16 228 43 3 248 62 154 13 0 134 46 191 23 1 180 187 206].


	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationVariableLayout [
	| object serialized materialized |
	"All Immediate classes are specially encoded, to have a test for every layout"
	object := Path root.
	
	self assert: object class classLayout class equals: VariableLayout.
	serialized := self  serializeToBytes: object.

	materialized := self materializeFromBytes: serialized.
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

	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object
]

{ #category : #'tests-layouts' }
SoilSerializationTest >> testSerializationWeakLayout [
	| object serialized materialized |
	"We use WeakArray as an exampe of a class with a WeakLayout"
	object := WeakArray with: 'String'.
	
	self assert: object class classLayout class equals: WeakLayout.
	serialized := self serializeToBytes: object.

	materialized := self  materializeFromBytes: serialized.
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

	materialized := self materializeFromBytes: serialized.
	self assert: materialized equals: object.
	self assert: materialized class equals: IntegerArray.
	self assert: materialized class classLayout class equals: WordLayout.
]
