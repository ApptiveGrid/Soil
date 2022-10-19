Class {
	#name : #SOMaterializer,
	#superclass : #FLMaterializer,
	#instVars : [
		'transaction',
		'record'
	],
	#category : #'Soil-Core-Fuel'
}

{ #category : #running }
SOMaterializer >> materializationClass [ 
	^ SOMaterialization
]

{ #category : #accessing }
SOMaterializer >> record: aSOObjectRecord [ 
	record := aSOObjectRecord 
]

{ #category : #running }
SOMaterializer >> runMaterialization [ 
	^ SOMaterialization new 
		record: record;
		run
]

{ #category : #accessing }
SOMaterializer >> transaction [

	^ transaction
]

{ #category : #accessing }
SOMaterializer >> transaction: anObject [

	transaction := anObject
]
