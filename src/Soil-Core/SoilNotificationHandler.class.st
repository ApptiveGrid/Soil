Class {
	#name : #SoilNotificationHandler,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #counting }
SoilNotificationHandler >> objectMaterialized: aSoilBehaviorDescription [
]

{ #category : #counting }
SoilNotificationHandler >> objectSerialized: anObject [ 

]

{ #category : #counting }
SoilNotificationHandler >> recordRead: aSoilCluster [
]

{ #category : #counting }
SoilNotificationHandler >> recordWritten: aSoilCluster [

]

{ #category : #accessing }
SoilNotificationHandler >> soil: anObject [

	soil := anObject
]

{ #category : #events }
SoilNotificationHandler >> transactionAborted: aSoilTransaction [
]

{ #category : #counting }
SoilNotificationHandler >> transactionCommitted: aSoilTransaction [ 
	 
	soil metadata transactionCommitted: aSoilTransaction
]

{ #category : #counting }
SoilNotificationHandler >> transactionCreated: aSoilTransaction [
]
