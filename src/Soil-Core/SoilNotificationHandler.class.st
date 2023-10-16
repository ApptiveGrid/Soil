Class {
	#name : #SoilNotificationHandler,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #counting }
SoilNotificationHandler >> clusterRead: aSoilCluster [
]

{ #category : #counting }
SoilNotificationHandler >> clusterWritten: aSoilCluster [

]

{ #category : #counting }
SoilNotificationHandler >> objectMaterialized: aSoilBehaviorDescription [
]

{ #category : #counting }
SoilNotificationHandler >> objectSerialized: anObject [ 

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
]

{ #category : #'as yet unclassified' }
SoilNotificationHandler >> transactionCreated: aSoilTransaction [
]
