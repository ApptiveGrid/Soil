"
The lint rules SoilCleanCodeTest applies to Soil-Core, applied to Soil-Resident:
its #packageToCheck answers `Soil package`, which is Soil-Core alone, so without
this the new package would be outside every structural check.

Three of the rules I bring myself. Two because the inherited versions are
`self skip` -- they carry known violations in Soil-Core that the new package does
not have, and skipping them here would give up a property that currently holds.
The third is the one a development image cannot show by itself: everything is
loaded, so a reference upwards into an embedder resolves here and fails only in
the build.
"
Class {
	#name : #SoilResidentCleanCodeTest,
	#superclass : #SoilCleanCodeTest,
	#category : #'Soil-Resident-Tests'
}

{ #category : #testing }
SoilResidentCleanCodeTest class >> shouldInheritSelectors [
	"Pharo inherits test selectors only from an abstract superclass, so without
	this the rules of SoilCleanCodeTest would not run against this package at all
	-- subclassing it would buy nothing but its helpers"
	^ true
]

{ #category : #accessing }
SoilResidentCleanCodeTest >> allowedPackageNames [
	"what Soil-Resident may reference: Soil's own packages, plus whatever Soil-Core
	already depends on. Computed rather than listed, so the set follows Soil-Core
	instead of going stale"
	| allowed |
	allowed := Set new.
	allowed
		addAll: ((PackageOrganizer default packages
			select: [ :each | each name beginsWith: 'Soil' ])
			collect: [ :each | each name ]).
	Soil package methods do: [ :method |
		self classesReferencedBy: method do: [ :class |
			class instanceSide package ifNotNil: [ :package | allowed add: package name ] ] ].
	^ allowed
]

{ #category : #helpers }
SoilResidentCleanCodeTest >> classesReferencedBy: aMethod do: aBlock [
	aMethod literals do: [ :literal |
		(literal isVariableBinding and: [ literal value isBehavior ])
			ifTrue: [ aBlock value: literal value ] ]
]

{ #category : #running }
SoilResidentCleanCodeTest >> packageToCheck [
	^ SoilResident package
]

{ #category : #tests }
SoilResidentCleanCodeTest >> testEveryClassHasAComment [
	"a class whose reason to exist is not written down is the one that gets used
	for the wrong thing"
	| undocumented |
	undocumented := self packageToCheck definedClasses
		select: [ :each | each comment isNil or: [ each comment isEmpty ] ].
	self
		assert: undocumented isEmpty
		description: 'the following classes have no comment: ' , undocumented asString
]

{ #category : #tests }
SoilResidentCleanCodeTest >> testNoReferencesOutsideSoilsOwnDependencies [
	"A development image has everything loaded, so a reference from here into an
	embedder resolves and the build is the first place it breaks. This is the
	check that catches it while it is still cheap."
	| allowed violations |
	allowed := self allowedPackageNames.
	violations := Dictionary new.
	self packageToCheck methods do: [ :method |
		self classesReferencedBy: method do: [ :class |
			class instanceSide package ifNotNil: [ :package |
				(allowed includes: package name) ifFalse: [
					(violations at: package name ifAbsentPut: [ Set new ])
						add: class name ] ] ] ].
	self
		assert: violations isEmpty
		description: 'Soil-Resident references classes outside Soil and its own dependencies: '
			, violations asString
]

{ #category : #tests }
SoilResidentCleanCodeTest >> testNoUncategorizedMethods [
	"inherited as skipped because Soil-Core carries known violations; the new
	package has none and should keep it that way"
	| uncategorized |
	uncategorized := self packageToCheck methods
		select: [ :method |
			method protocolName isNil
				or: [ method protocolName = Protocol unclassified ] ].
	self
		assert: uncategorized isEmpty
		description: 'the following methods are uncategorized: ' , uncategorized asString
]
