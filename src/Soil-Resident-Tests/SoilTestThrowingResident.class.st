"
I throw on every question and on every nudge. Starting is the one thing I do
without complaint, so the supervisor gets me into #started and then has to
survive me.
"
Class {
	#name : #SoilTestThrowingResident,
	#superclass : #SoilResident,
	#category : #'Soil-Resident-Tests'
}

{ #category : #testing }
SoilTestThrowingResident >> basicHasPendingWork [
	self error: 'deliberately failing to answer hasPendingWork'
]

{ #category : #testing }
SoilTestThrowingResident >> basicIsIdle [
	self error: 'deliberately failing to answer isIdle'
]

{ #category : #stopping }
SoilTestThrowingResident >> flushOnStop [
	self error: 'deliberately failing to flush'
]

{ #category : #accessing }
SoilTestThrowingResident >> name [
	^ #throwing
]

{ #category : #running }
SoilTestThrowingResident >> tick [
	self error: 'deliberately failing on tick'
]
