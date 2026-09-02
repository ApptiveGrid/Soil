Class {
	#name : #SoilTestFailingResident,
	#superclass : #SoilResident,
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilTestFailingResident >> name [
	^ #failing
]

{ #category : #running }
SoilTestFailingResident >> startIn: aTransaction [
	self error: 'deliberately failing to start'
]
