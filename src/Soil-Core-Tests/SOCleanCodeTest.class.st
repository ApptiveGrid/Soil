Class {
	#name : #SOCleanCodeTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #cleanup }
SOCleanCodeTest class >> cleanupWhiteSpaceTrimRight [
	<script>
	| badCases |
	badCases := (Soil
	package methods, self package methods) select: [ :each |
		            each sourceCode trimRight size ~= each sourceCode size ].

	badCases do: [ :each |
		| refactoring classOrTrait |
		classOrTrait := each traitSource
			                ifNil: [ each methodClass ]
			                ifNotNil: [ each traitSource innerClass ].
		refactoring := RBAddMethodChange
			               compile: each sourceCode trimRight
			               in: classOrTrait
			               for: nil.
		refactoring execute ]
]

{ #category : #tests }
SOCleanCodeTest >> testCodeCoverage [

	| collector methods coverage testClasses perMethodCoveragePercentage |

	self skip.
	"take care: this test interferes with the run coverage feature in the testRunner, we should improve
	it to not run test tagged <ignoreForCoverage>"
	collector :=Smalltalk globals at: #CoverageCollector ifPresent: [:class | class new] ifAbsent: [self error: 'class CoverageCollector not found' ].
	methods := Soil package methods.
	"Remove all the methods and classes we are not interested in"

	"subclassResponsibility methods"
	methods := methods reject: [ :method |
		           method isAbstract ].

	"all methods tagged with <ignoreForCoverage>"
	methods := methods reject: [ :method |
		           method hasPragmaNamed: #ignoreForCoverage ].

	"remove all method from classes in #classNamesNotUnderTest"
	methods := methods reject: [ :method |
		           SoilTest classNamesNotUnderTest includes:
			           method methodClass instanceSide name ].

	collector methods: methods.

	testClasses := self class package definedClasses select: [ :each |
		               each isTestCase ].
	"we need to remove this test, just remove the whole class for now
	(we should ignore test tagged with <ignoreForCoverage>)"
	testClasses := testClasses copyWithout: self class.

	coverage := collector runOn: [
		            testClasses do: [ :class | class buildSuite run ] ].
	perMethodCoveragePercentage := (100.0 * coverage methods size / coverage collector methods size) rounded.

	self assert: perMethodCoveragePercentage >= 93
]

{ #category : #tests }
SOCleanCodeTest >> testNoDuplicatedMethodInHierarchy [
	"There should be no methods in the hierachy that are already in a superclass"

	| methods |
	methods :=  Soil package methods reject: [:method | method isFromTrait].
	methods := methods select: [:method |
	method methodClass superclass
 		ifNotNil: [ :superclass | (superclass lookupSelector: method selector)
 			ifNotNil: [ :overridenMethod | method equivalentTo: overridenMethod ]
 			ifNil: [ false ] ]
 		ifNil: [ false ]].
		self
		assert: methods isEmpty
		description: ('the following methods are already in the superclass hierarchy and can be removed: ', methods asString)
]

{ #category : #tests }
SOCleanCodeTest >> testNoUncategorizedMethods [
	"Check that we have no #'as yet unclassified' protocols left"

	| violating classes |
	self skip.
	classes := Soil package definedClasses
	           , (Soil package definedClasses collect: [ :each | each classSide ]).

	violating := classes select: [ :class |
		             class protocols includes: #'as yet unclassified' ].
	self
		assert: violating isEmpty
		description: 'the following classes have uncategorized methods: ', violating asString
]

{ #category : #tests }
SOCleanCodeTest >> testNoUnimplementedCalls [

	| remaining |
	remaining := Soil package methods select: [ :meth |
		             | ignored |
		             ignored := (meth pragmaAt: #ignoreUnimplementedCalls:)
			                        ifNotNil: [ :pragma | pragma argumentAt: 1 ]
			                        ifNil: [ #(  ) ].
		             meth messages anySatisfy: [ :m |
			             m isSelectorSymbol not and: [
				             (ignored includes: m) not ] ] ].

	self assert: remaining isEmpty description: ('the following methods send selectors that do not exist', remaining asString)
]

{ #category : #tests }
SOCleanCodeTest >> testNoUnsentMessages [
	"Fail if there are methods implemented whose selectors is not sent anywhere in Pharo.
	Please add a test or remove the method!"

	| found knownviolations |
	found := Soil package allUnsentMessages.

	"To be fixed, see https://github.com/ApptiveGrid/Soil/issues/24"
	knownviolations :=
	 #('versionSize' 'flock:operation:' 'canLock:from:to:exclusive:' 'setNonBlock:' 'transaction' 'releaseLockAndClose' 'canLock:from:to:exclusive:' 'soilLoadedIn:' 'idOf:' 'inspectionObject' 'soilRawSerialize:' 'soilRawMaterialize:' 'unlockAt:length:' 'lockAt:length:').

	found := found copyWithoutAll: knownviolations.

	self
		assert: found isEmpty
		description: ('the following selectors are implemented, but never send', found asString)
]

{ #category : #tests }
SOCleanCodeTest >> testNoUnusedClasses [
	"Fail if there are Classes that are not used. They should either be tested or deleted.
	(check how to override #isUsed for cases where classes are discovered reflectively)"
	| found  knownviolations |
	found := Soil package definedClasses reject: [ :class | class isUsed].

	knownviolations := #().
	found := found reject: [:class | knownviolations includes: class name  ].

	self
		assert: found isEmpty
		description: ('the following classes are unused: ', found asString)
]

{ #category : #tests }
SOCleanCodeTest >> testNoUnusedInstanceVariablesLeft [
	| variables classes validExceptions remaining |
	classes := Soil package definedClasses
	           , (Soil package definedClasses collect: [ :each | each classSide ]).

	variables := classes flatCollect: [ :each | each instanceVariables ].
	variables := variables reject: [ :each | each isReferenced ].

	classes := variables collect: [ :each | each definingClass ] as: Set.

	validExceptions := {}.

	remaining := classes asOrderedCollection removeAll: validExceptions; yourself.
	self assert: remaining isEmpty description: ('the following classes have unused instance variables and should be cleaned: ', remaining asString)
]

{ #category : #tests }
SOCleanCodeTest >> testNoUnusedTemporaryVariablesLeft [
	"Fail if there are methods who have unused temporary variables"
	| found  |
	found := Soil package methods select: [ :m |
		m hasTemporaries and: [ m ast temporaries anySatisfy: [ :x | x binding isUsed not] ] ].

	self
		assert: found isEmpty
		description: ('the following methods have unused temporary variables and should be cleaned: ', found asString)
]
