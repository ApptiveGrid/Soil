"
A passive resident: it collects bookings in memory and flushes them on stop, in
a transaction of its own. It has no process, so #requestStop has to take it to
#stopped right away -- nobody would notice the flag otherwise.
"
Class {
	#name : #SoilTestPassiveResident,
	#superclass : #SoilResident,
	#instVars : [
		'bookings'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #testing }
SoilTestPassiveResident >> basicIsIdle [
	"a passive resident is never busy -- it is consulted, it does not work"
	^ true
]

{ #category : #accessing }
SoilTestPassiveResident >> book [
	bookings := bookings + 1
]

{ #category : #accessing }
SoilTestPassiveResident >> bookings [
	^ bookings
]

{ #category : #stopping }
SoilTestPassiveResident >> flushOnStop [
	"my own transaction, committed by me. The supervisor's stop transaction stays
	reading, and with nothing pending there is no write at all"
	bookings = 0 ifTrue: [ ^ self ].
	self withTransactionDo: [ :txn |
		| space |
		space := self workspaceIn: txn.
		space at: #flushed put: (space at: #flushed) + bookings.
		txn commit ].
	bookings := 0
]

{ #category : #initialization }
SoilTestPassiveResident >> initialize [
	super initialize.
	bookings := 0
]

{ #category : #accessing }
SoilTestPassiveResident >> name [
	^ #passive
]
