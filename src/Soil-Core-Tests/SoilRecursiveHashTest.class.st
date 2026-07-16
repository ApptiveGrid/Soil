Class {
	#name : #SoilRecursiveHashTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #tests }
SoilRecursiveHashTest >> testCollectionPositionExchanged [
	| array hash1 tmp hash2 |
	array := Array with: #foo with: #bar.
	hash1 := array soilRecursiveHash.
	tmp := array at: 1.
	array at: 1 put: (array at: 2).
	array at: 2 put: tmp.
	hash2 := array soilRecursiveHash.
	self deny: hash1 equals: hash2
]

{ #category : #tests }
SoilRecursiveHashTest >> testCollectionPositionExchangedImmediateInt [
	| array hash1 tmp hash2 |
	"test that the position detection in Collection works if the basicIdentityHashes are close"
	array := Array with: 3 with: 1.
	hash1 := array soilRecursiveHash.
	tmp := array at: 1.
	array at: 1 put: (array at: 2).
	array at: 2 put: tmp.
	hash2 := array soilRecursiveHash.
	self deny: hash1 equals: hash2
]

{ #category : #tests }
SoilRecursiveHashTest >> testDictionaryKeysExchanged [
	| dict hash1 hash2 key1 key2 value1 value2 |
	key1 := 'foo1'.
	key2 := 'foo2'.
	value1 := 'bar1'.
	value2 := 'bar2'.
	dict := { key1 -> value1. key2 -> value2 } asDictionary.
	hash1 := dict soilRecursiveHash.
	self assert: hash1 equals: dict soilRecursiveHash.	
	"order of key addition should not change the hash"
	dict removeKey: key1.
	dict at: key1 put: value1.
	self deny: hash1 equals: dict soilRecursiveHash.	
	"absolute position in the internal array should also not change
	the hash"
	dict removeKey: key2.
	dict at: 'foo3' put: 'bar3'.
	dict at: key2 put: value2.
	dict removeKey: 'foo3'.
	hash2 := dict soilRecursiveHash.
	self deny: hash1 equals: hash2
]

{ #category : #tests }
SoilRecursiveHashTest >> testImmediateCharacter [
	| hash |
	hash := $A soilRecursiveHash.
	self deny: hash equals: 65
]

{ #category : #tests }
SoilRecursiveHashTest >> testImmediateMappingProblem [ 
	"immediate values do not have their type into value so this can
	be exchanged and producing the same hash"
	self deny: 65 soilRecursiveHash equals: $A soilRecursiveHash 

]

{ #category : #tests }
SoilRecursiveHashTest >> testImmediateSmallInteger [
	| hash |
	hash := 65 soilRecursiveHash.
	self deny: hash equals: 65
]

{ #category : #tests }
SoilRecursiveHashTest >> testObject [ 
	| object |
	object := SoilRecursiveHashTestObject new.
	object 
		one: { 1 . 1.23 . 1.23s2 . 1/3. true. nil. $A. #symbol . 'string'};
		two: DateAndTime now;
		three: { #key -> #value } asDictionary.
	self assert: object soilRecursiveHash equals: object soilRecursiveHash 
	
]
