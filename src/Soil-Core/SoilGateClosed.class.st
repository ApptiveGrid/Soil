"
I am signalled when the gate of the database is closed (#closeGate, #gateDo:, #drainedGateDo:, #garbageCollect) and another process asks for a transaction or a commit. The same goes for closing a gate that is closed already, and for opening one that another process closed.

The gate lasts as long as one operation, so a caller that serves requests answers me with a temporary refusal, e.g. 503 with a retry hint over HTTP. #holder is the process that closed the gate.
"
Class {
	#name : #SoilGateClosed,
	#superclass : #SoilError,
	#instVars : [
		'holder'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilGateClosed >> holder [
	^ holder
]

{ #category : #accessing }
SoilGateClosed >> holder: aProcess [
	holder := aProcess
]
