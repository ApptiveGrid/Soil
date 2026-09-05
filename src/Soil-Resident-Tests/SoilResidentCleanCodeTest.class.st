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
SoilResidentCleanCodeTest >> allowedClasses [
	"the classes Soil-Core's own source already references. That is the right
	yardstick for two different worries at once: they are inside what Soil depends
	on, and they are safe across every Pharo version in Soil's build matrix,
	because Soil-Core is built against all of them.

	Computed rather than listed, so the set follows Soil-Core instead of going
	stale. Only `Soil package` is consulted -- enumerating packages by name needs
	an organizer whose own class name differs across those Pharo versions, which
	is exactly the kind of slip this test exists to catch."
	| allowed |
	allowed := Set new.
	Soil package methods do: [ :method |
		self classesReferencedBy: method do: [ :class | allowed add: class instanceSide ] ].
	^ allowed
]

{ #category : #helpers }
SoilResidentCleanCodeTest >> classesReferencedBy: aMethod do: aBlock [
	aMethod literals do: [ :literal |
		(literal isVariableBinding and: [ literal value isBehavior ])
			ifTrue: [ aBlock value: literal value ] ]
]

{ #category : #accessing }
SoilResidentCleanCodeTest >> isOwnClass: aClass [
	"Soil's own classes need no further justification"
	^ aClass instanceSide package
		ifNotNil: [ :package | package name beginsWith: 'Soil' ]
		ifNil: [ false ]
]

{ #category : #running }
SoilResidentCleanCodeTest >> packageToCheck [
	^ SoilResident package
]

{ #category : #helpers }
SoilResidentCleanCodeTest >> protocolNameOf: aMethod [
	"how a method is asked for its protocol differs across the Pharo versions this
	builds on. Try what is there -- and fail loudly rather than answer nil if
	nothing is, because a silent nil would leave this check green and empty, which
	is the failure mode it exists to prevent."
	| protocol |
	(aMethod respondsTo: #protocolName) ifTrue: [ ^ aMethod protocolName ].
	(aMethod respondsTo: #protocol) ifTrue: [
		protocol := aMethod protocol.
		^ protocol ifNotNil: [
			protocol isString
				ifTrue: [ protocol ]
				ifFalse: [ protocol name ] ] ].
	self fail: 'no known way to ask a CompiledMethod for its protocol in this Pharo'
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
	"Two things a development image cannot show by itself. Everything is loaded
	here, so a reference upwards into an embedder resolves and the build is the
	first place it breaks. And every Pharo version in the build matrix is loaded
	as one -- a class that exists only in the newest of them resolves here too.

	Compared per class, not per package: PackageOrganizer sits in a package
	Soil-Core does reference, so a package-granular check let it through and the
	Pharo 11 build was the first to say so."
	| allowed violations |
	allowed := self allowedClasses.
	violations := Set new.
	self packageToCheck methods do: [ :method |
		self classesReferencedBy: method do: [ :class |
			((allowed includes: class instanceSide)
				or: [ self isOwnClass: class ]) ifFalse: [
					violations add: class instanceSide name ] ] ].
	self
		assert: violations isEmpty
		description: 'Soil-Resident references classes that Soil itself does not use, so they are neither known to be dependencies nor known to exist in every supported Pharo: '
			, violations asSortedCollection asArray asString
]

{ #category : #tests }
SoilResidentCleanCodeTest >> testNoUncategorizedMethods [
	"inherited as skipped because Soil-Core carries known violations; the new
	package has none and should keep it that way.

	Asked per method rather than per class. The class-side variant that the
	inherited version uses walks metaclasses, and #protocolNames is not on the
	metaclass path in every Pharo of the build matrix -- which nobody noticed
	because the inherited version never ran. Package>>methods covers both sides
	anyway."
	| uncategorized |
	uncategorized := self packageToCheck methods select: [ :method |
		| protocol |
		protocol := self protocolNameOf: method.
		protocol isNil or: [ protocol asString = 'as yet unclassified' ] ].
	self
		assert: uncategorized isEmpty
		description: 'the following methods are uncategorized: ' , uncategorized asString
]
