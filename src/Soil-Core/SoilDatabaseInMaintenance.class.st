"
I am signalled when a database is opened while its maintenance marker is there (#maintenanceMarkerPath, maintenance.lock). The marker is set from the outside, by touch, and stays until somebody removes it; #openForMaintenance opens anyway.

A caller that serves requests answers me with a refusal that lasts, e.g. 503 over HTTP. #marker is the file that refused.
"
Class {
	#name : #SoilDatabaseInMaintenance,
	#superclass : #SoilError,
	#instVars : [
		'marker'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseInMaintenance >> marker [
	^ marker
]

{ #category : #accessing }
SoilDatabaseInMaintenance >> marker: aFileReference [
	marker := aFileReference
]

{ #category : #accessing }
SoilDatabaseInMaintenance >> messageText [
	^ messageText ifNil: [ 'database is in maintenance: ', marker fullName ]
]
