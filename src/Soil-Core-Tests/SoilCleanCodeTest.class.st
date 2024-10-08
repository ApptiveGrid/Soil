Class {
	#name : #SoilCleanCodeTest,
	#superclass : #TestCase,
	#pools : [
		'SoilTypeCodes'
	],
	#category : #'Soil-Core-Tests-CleanCode'
}

{ #category : #cleanup }
SoilCleanCodeTest class >> cleanupWhiteSpaceTrimRight [
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

{ #category : #running }
SoilCleanCodeTest >> assertValidLintRule: aLintRule [
	self assertValidLintRule: aLintRule withExceptions: #()
]

{ #category : #running }
SoilCleanCodeTest >> assertValidLintRule: aLintRule withExceptions: someNames [
	| runner results |
	runner := ReSmalllintChecker new.
	runner
		rule: {aLintRule};
		environment: ( RBBrowserEnvironment new
		forClasses: self packageToCheck definedClasses);
		run.

	results := (runner criticsOf: aLintRule) reject: [ :critique | someNames includes: critique entity name ].
	self
		assert: results isEmpty
		description: [ String
				streamContents: [ :s |
					s
						<< aLintRule rationale;
						lf;
						<< 'Violations: ';
						lf.
					results
						do: [ :e |
							s
								<< '- ';
								print: e entity ]
						separatedBy: [ s lf ] ] ]
]

{ #category : #running }
SoilCleanCodeTest >> packageToCheck [
	^ Soil package
]

{ #category : #tests }
SoilCleanCodeTest >> testCodeCoverage [

	| collector methods coverage testClasses perMethodCoveragePercentage |
	
	self skip.
	"take care: this test interferes with the run coverage feature in the testRunner, we should improve
	it to not run test tagged <ignoreForCoverage>"
	collector :=Smalltalk globals at: #CoverageCollector ifPresent: [:class | class new] ifAbsent: [self error: 'class CoverageCollector not found' ].
	methods := self packageToCheck methods.
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
	
	self assert: perMethodCoveragePercentage >= 93.
]

{ #category : #tests }
SoilCleanCodeTest >> testNoDuplicatedMethodInHierarchy [
	"There should be no methods in the hierachy that are already in a superclass"
	
	| methods |
	methods := self packageToCheck methods reject: [:method | method isFromTrait].
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
SoilCleanCodeTest >> testNoShadowedVariablesInMethods [
	"Fail if there are methods who define shadowed temps or args"
	| found validExceptions remaining |
	found := self packageToCheck methods select: [ :m |
		m isQuick not and: [ "quick methods do not define variables"
			m ast variableDefinitionNodes anySatisfy: [ :node | node variable isShadowing ] ]].
	"No other exceptions beside the ones mentioned here should be allowed"
	validExceptions := { }.

	remaining := found asOrderedCollection
								removeAll: validExceptions;
								yourself.

	self
		assert: remaining isEmpty
		description: ('the following methods have shadowing variable definitions and should be cleaned: ', remaining asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUncategorizedMethods [
	"Check that we have no #'as yet unclassified' protocols left"

	| violating classes |
	self skip.
	classes := self packageToCheck definedClasses
	           , (self packageToCheck definedClasses collect: [ :each | each classSide ]).

	violating := classes select: [ :class | 
		             class protocolNames includes: #'as yet unclassified' ].
	self
		assert: violating isEmpty
		description: 'the following classes have uncategorized methods: ', violating asString
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUnimplementedCalls [

	| remaining |
	"To tag selectors send that are not implemented that should not trigger this rule, use the pragma 
	<ignoreNotImplementedSelectors: #(selector:to:be:ignored)>"
	
	self skip.
	remaining := self packageToCheck methods select: [ :meth | 
		             | ignored |
		             ignored := meth allIgnoredNotImplementedSelectors.
						 meth messages anySatisfy: [ :m | 
			             m isSelectorSymbol not and: [ 
				             (ignored includes: m) not ] ] ].
	
	self assert: remaining isEmpty description: ('the following methods send selectors that do not exist', remaining asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUnsentMessages [
	"Fail if there are methods implemented whose selectors is not sent anywhere in Pharo.
	Please add a test or remove the method!"

	| found methods|
	"As this is not critical, we skip this test. If you are want to cleanup, just run it!"
	self skip.
	found := self packageToCheck allUnsentMessages.
	methods := self packageToCheck methods select: [ :method | found includes: method selector ].
	methods := methods reject: [:method | method hasPragmaNamed: #inspectorPresentationOrder:title:
  ].
	
	self
		assert: methods isEmpty
		description: ('the following selectors are implemented, but never send', methods asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUnusedClasses [
	"Fail if there are Classes that are not used. They should either be tested or deleted.
	(check how to override #isUsed for cases where classes are discovered reflectively)"
	| found  knownviolations |
	"As this is not critical, we skip this test. If you are want to cleanup, just run it!"
	self skip.
	found := self packageToCheck definedClasses reject: [ :class | class isUsed]. 
	
	knownviolations := #( ).
	found := found reject: [:class | knownviolations includes: class name  ].
	
	self 
		assert: found isEmpty 
		description: ('the following classes are unused: ', found asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUnusedInstanceVariablesLeft [
	| variables classes validExceptions remaining |
	classes := self packageToCheck definedClasses
	           , (self packageToCheck definedClasses collect: [ :each | each classSide ]).
	
	variables := classes flatCollect: [ :each | each instanceVariables ].
	variables := variables reject: [ :each | each isReferenced ].
	
	classes := variables collect: [ :each | each definingClass ] as: Set.
	
	validExceptions := {}.	
	
	remaining := classes asOrderedCollection removeAll: validExceptions; yourself.
	self assert: remaining isEmpty description: ('the following classes have unused instance variables and should be cleaned: ', remaining asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoUnusedTemporaryVariablesLeft [
	"Fail if there are methods who have unused temporary variables"
	| found  |
	found := self packageToCheck methods select: [ :m | 
		m hasTemporaries and: [ m ast temporaries anySatisfy: [ :x | x binding isUsed not] ] ].
							
	self 
		assert: found isEmpty 
		description: ('the following methods have unused temporary variables and should be cleaned: ', found asString)
]

{ #category : #tests }
SoilCleanCodeTest >> testNoVarsDefinedByClassesShadow [
	"make sure no class vars or ivars shadow"
	| classes |
	classes := self packageToCheck definedClasses select: [ :class |
		           class definedVariables anySatisfy: [ :var |
			           var isShadowing ] ].

	self assert: classes isEmpty description: classes asArray asString
]

{ #category : #tests }
SoilCleanCodeTest >> testReDoNotSendSuperInitializeInClassSideRule [
	self assertValidLintRule: ReDoNotSendSuperInitializeInClassSideRule new
]

{ #category : #tests }
SoilCleanCodeTest >> testReInstanceVariableCapitalizationRule [
	self assertValidLintRule: ReInstanceVariableCapitalizationRule new
]
