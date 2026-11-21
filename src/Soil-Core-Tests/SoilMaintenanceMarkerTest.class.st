"
I test the maintenance marker: a file that keeps a database from being opened just by being there, set from the outside by touch.
"
Class {
	#name : #SoilMaintenanceMarkerTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'other'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilMaintenanceMarkerTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-maintenance-marker-tests')
		destroy;
		initializeFilesystem;
		yourself.
	soil close.
	other := Soil new path: soil path
]

{ #category : #running }
SoilMaintenanceMarkerTest >> tearDown [
	super tearDown.
	other isOpen ifTrue: [ other close ].
	other unlockExclusive.
	soil maintenanceMarkerPath ensureDelete
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testClaimOfAMarkedDatabaseIsRefused [
	"refused before the claim: claimed, the database would stay with a process that
	cannot open it"
	soil maintenanceMarkerPath ensureCreateFile.
	self should: [ other lockExclusive ] raise: SoilDatabaseInMaintenance.
	self deny: other holdsExclusiveLock
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testForMaintenanceDoClaimsAndOpensAMarkedDatabase [
	soil maintenanceMarkerPath ensureCreateFile.
	other forMaintenanceDo: [
		other
			lockExclusive;
			open ].
	self assert: other holdsExclusiveLock.
	self assert: other isOpen
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testMarkedDatabaseDoesNotOpen [
	| error |
	soil maintenanceMarkerPath ensureCreateFile.
	error := [ other open. nil ] on: SoilDatabaseInMaintenance do: [ :e | e ].
	self assert: (error isKindOf: SoilDatabaseInMaintenance).
	self assert: error marker equals: soil maintenanceMarkerPath.
	self deny: other isOpen
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testMarkerDoesNotTouchAnOpenDatabase [
	"the marker keeps a database from being opened, it does not close one"
	other open.
	soil maintenanceMarkerPath ensureCreateFile.
	other newTransaction abort.
	self assert: other isOpen
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testOpenForMaintenanceDoesNotLast [
	"the permission is the call: closed and opened again, the marker refuses"
	soil maintenanceMarkerPath ensureCreateFile.
	other openForMaintenance.
	other close.
	self should: [ other open ] raise: SoilDatabaseInMaintenance.
	self deny: other isOpen
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testOpenForMaintenanceOpensAMarkedDatabase [
	soil maintenanceMarkerPath ensureCreateFile.
	other openForMaintenance.
	self assert: other isOpen.
	self assert: other isMarkedForMaintenance
]

{ #category : #tests }
SoilMaintenanceMarkerTest >> testRemovingTheMarkerAllowsOpening [
	soil maintenanceMarkerPath ensureCreateFile.
	self should: [ other open ] raise: SoilDatabaseInMaintenance.
	soil maintenanceMarkerPath delete.
	other open.
	self assert: other isOpen
]
