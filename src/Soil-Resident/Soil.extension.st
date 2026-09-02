Extension { #name : #Soil }

{ #category : #'*Soil-Resident' }
Soil >> newResidentSupervisor [
	^ self residentSupervisorClass new
		soil: self;
		yourself
]

{ #category : #'*Soil-Resident' }
Soil >> residentRegistryIn: aTransaction [
	"the way to the persisted residents of this database, overridable by a
	subclass. What it deliberately is not: a pointer outwards and a structural
	requirement. An embedder needs neither a dictionary as its root nor a
	reserved key nor a registration with Soil -- the way lies here and is merely
	overridable.

	The default answers nil: a plain Soil database has no residents. Once Soil
	has named roots this default reads the registry's object id from there, and
	an embedder's override falls away."
	^ nil
]
{ #category : #'*Soil-Resident' }
Soil >> residentSupervisorClass [
	^ SoilResidentSupervisor
]

