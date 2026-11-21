"
I am signalled when a database is opened while its maintenance marker is there (#maintenanceMarkerPath, maintenance.lock). The marker is set from the outside, by touch, and stays until somebody removes it; #lockExclusive refuses the same way. #openForMaintenance opens anyway, and #forMaintenanceDo: lets both through: they resume me.

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

{ #category : #testing }
SoilDatabaseInMaintenance >> isResumable [
	"resumed, the open or the claim goes on: that is how #forMaintenanceDo: lets the one
	who does the maintenance through without a flag that would outlast it"
	^ true
]

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
