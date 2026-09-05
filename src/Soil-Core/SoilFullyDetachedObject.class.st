"
I am an object that has left its transaction behind.

A SoilObjectProxy is bound to one transaction and resolves through it. I am the
opposite: I am minted inside a transaction, take the object and its objectId with
me, and from then on live without one. Sends reach the object I hold, and I ask
nobody. That is what ""detached"" means -- outside a transaction, and also
entirely without one.

I am for owners that outlive transactions: a resident holds only its
descriptionId and no materialized object, but the work it does needs one. I am
where that object is allowed to live.

Two things I keep, and each has a job. The object answers the sends. The
objectId is how somebody writes it back later, without having to find it again.

Writing back is deliberately not mine. I only report that something happened, by
way of #changed, which I leave empty -- my subclasses give it a meaning. The one
who is told decides when and in which transaction the write happens, and can
coalesce a burst of changes into a single one.

What may be handed to me is what is a plain object once materialized. A
Soil-managed collection is only half detachable: reading from a detached
SoilPersistentDictionary still works, but writing does not, because #at:put: has
to make the stored value a cluster root and that needs a transaction.

The contract that carries all of this: I am the only writer of my object. A
second writer's change would be overwritten silently by the next write-back,
because I hand out the object I hold and not what is currently in the store.
"
Class {
	#name : #SoilFullyDetachedObject,
	#superclass : #ProtoObject,
	#instVars : [
		'objectId',
		'object'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilFullyDetachedObject class >> on: anObject in: aTransaction [
	"minted inside a transaction, which is the only one I ever need: it knows the
	object and its id.

	What I take is the real object, never a SoilObjectProxy: a cluster root is
	handed out as a proxy, and a proxy resolves through the transaction it was
	loaded in. Holding one would make me fail the moment that transaction is gone,
	which is precisely the situation I exist for.

	Written out rather than as a cascade on purpose. #yourself is not defined on
	ProtoObject, so it goes through #doesNotUnderstand: and answers the object I
	hold -- and that is deliberate, the way a wrapper is unwrapped, as it is on
	SoilObjectProxy. A cascade ending in #yourself would therefore hand out the
	object instead of me."
	| detached real |
	real := anObject theNonSoilProxy.
	detached := self new.
	detached setObject: real objectId: (aTransaction objectIdOf: real).
	^ detached
]

{ #category : #converting }
SoilFullyDetachedObject >> asSoilObjectId [
	^ objectId
]

{ #category : #notifying }
SoilFullyDetachedObject >> changed [
	"something about my object changed. I do nothing with that -- subclasses tell
	whoever is responsible for writing it back"
]

{ #category : #'reflective operations' }
SoilFullyDetachedObject >> doesNotUnderstand: aMessage [
	^ aMessage sendTo: object
]

{ #category : #fuel }
SoilFullyDetachedObject >> fuelAccept: aGeneralMapper [
	^ aGeneralMapper
		visitSubstitution: self
		by: object
]

{ #category : #fuel }
SoilFullyDetachedObject >> fuelReplacement [
	"I must never end up in the store myself: I am a handle, not content. Whoever
	serializes a graph I am part of gets the object instead"
	^ object
]

{ #category : #testing }
SoilFullyDetachedObject >> isEqualTo: anObject [
	"see #isIdenticalTo: for why the objectId decides"
	anObject isSoilProxy ifTrue: [ ^ objectId = anObject objectId ].
	^ object = anObject
]

{ #category : #testing }
SoilFullyDetachedObject >> isIdenticalTo: anObject [
	"whenever the other side stands in for a stored object too, the objectId is the
	criterion and not the materialized object. Two handles on the same stored
	object are the same thing even when they hold different materializations of it
	-- which is exactly what two detached objects minted in different transactions
	do, because each transaction materializes its own."
	anObject isSoilProxy ifTrue: [ ^ objectId = anObject objectId ].
	^ object == anObject
]

{ #category : #testing }
SoilFullyDetachedObject >> isNil [
	^ object isNil
]

{ #category : #testing }
SoilFullyDetachedObject >> isSoilProxy [
	"yes. Not because I resolve through a transaction -- I do not -- but because
	that is what everyone who asks this means: a stand-in for a stored object,
	which must not be compared with #== and knows how to compare itself. It is
	also why I descend from ProtoObject, so that as little as possible is answered
	without going through #doesNotUnderstand:."
	^ true
]

{ #category : #accessing }
SoilFullyDetachedObject >> objectId [
	^ objectId
]

{ #category : #printing }
SoilFullyDetachedObject >> printOn: aStream [
	aStream << 'detached ' << objectId asString << ': '.
	object printOn: aStream
]

{ #category : #printing }
SoilFullyDetachedObject >> printString [
	^ String streamContents: [ :s | self printOn: s ] limitedTo: 1000
]

{ #category : #initialization }
SoilFullyDetachedObject >> setObject: anObject objectId: anObjectId [
	object := anObject.
	objectId := anObjectId
]

{ #category : #accessing }
SoilFullyDetachedObject >> soilRealObject [
	"no resolving, no lookup: I have had it all along"
	^ object
]

{ #category : #soil }
SoilFullyDetachedObject >> soilSerialize: aSerializer [
	^ object soilSerialize: aSerializer
]

{ #category : #soil }
SoilFullyDetachedObject >> theNonSoilProxy [
	^ object
]
