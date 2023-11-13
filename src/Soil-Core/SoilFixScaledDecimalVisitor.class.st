Class {
	#name : #SoilFixScaledDecimalVisitor,
	#superclass : #SoilObjectVisitor,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilFixScaledDecimalVisitor >> visitPersistentClusterVersion: aPersistentClusterVersion [ 
	| object materializer |
	"use a materializer that can read the legacy format of a 
	scaled decimal"
	materializer := SoilFixScaledDecimalMaterializer new 
		transaction: transaction.
	object := aPersistentClusterVersion
		transaction: transaction;
		materializeObjectUsing: materializer.
		materializer found ifTrue: [
			"if the materializer found a scaled decimal we need to add the raw read
			object to the transaction in order to mark it dirty" 
			transaction 
				registerRecord: aPersistentClusterVersion;
				markDirty: object.  ].
	super visitPersistentClusterVersion: aPersistentClusterVersion.
]
