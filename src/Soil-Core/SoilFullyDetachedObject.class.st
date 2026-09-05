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

	Written out rather than as a cascade on purpose: a cascade ends in #yourself,
	and on a forwarding proxy that is a trap -- see my own #yourself"
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
	^ object = anObject
]

{ #category : #testing }
SoilFullyDetachedObject >> isIdenticalTo: anObject [
	^ object == anObject
]

{ #category : #testing }
SoilFullyDetachedObject >> isNil [
	^ object isNil
]

{ #category : #testing }
SoilFullyDetachedObject >> isSoilProxy [
	"no -- a proxy resolves through a transaction, and that is exactly what I do
	not do"
	^ false
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

{ #category : #accessing }
SoilFullyDetachedObject >> yourself [
	"ProtoObject does not have it, so without this it would go through
	#doesNotUnderstand: and answer the object I hold instead of me -- which turns
	every cascade that ends in #yourself into a silent unwrapping"
	^ self
]

{ #category : #soil }
SoilFullyDetachedObject >> theNonSoilProxy [
	^ object
]
