Class {
	#name : #SoilFabric,
	#superclass : #Object,
	#instVars : [
		'transactionClass',
		'materializerClass',
		'serializerClass',
		'applicationMigrationClass'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilFabric >> applicationMigrationClass [

	^ applicationMigrationClass ifNil: [ 
		applicationMigrationClass := self defaultApplicationMigrationClass ]
]

{ #category : #accessing }
SoilFabric >> applicationMigrationClass: aClass [

	applicationMigrationClass := aClass
]

{ #category : #'instance creation' }
SoilFabric >> defaultApplicationMigrationClass [
	^ SoilApplicationMigration 
]

{ #category : #'instance creation' }
SoilFabric >> defaultMaterializerClass [
	^ SoilMaterializer
]

{ #category : #'instance creation' }
SoilFabric >> defaultSerializerClass [
	^ SoilSerializer
]

{ #category : #accessing }
SoilFabric >> defaultTransactionClass [
	^ SoilTransaction 
]

{ #category : #accessing }
SoilFabric >> materializerClass [

	^ materializerClass ifNil: [ 
		materializerClass := self defaultMaterializerClass ]
]

{ #category : #accessing }
SoilFabric >> materializerClass: anObject [

	materializerClass := anObject
]

{ #category : #accessing }
SoilFabric >> serializerClass [

	^ serializerClass ifNil: [ 
		serializerClass := self defaultSerializerClass  ]
]

{ #category : #accessing }
SoilFabric >> serializerClass: anObject [

	serializerClass := anObject
]

{ #category : #accessing }
SoilFabric >> transactionClass [ 
	^ transactionClass ifNil: [ 
		transactionClass := self defaultTransactionClass ]
]

{ #category : #accessing }
SoilFabric >> transactionClass: aClass [
	transactionClass := aClass
]
