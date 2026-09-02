Class {
	#name : #BaselineOfSoil,
	#superclass : #BaselineOf,
	#category : #BaselineOfSoil
}

{ #category : #baselines }
BaselineOfSoil >> baseline: spec [
	<baseline>

	spec for: #'common' do: [
		spec package: #'Soil-File' with: [  ].
		spec package: #'Soil-File-Tests' with: [ spec requires: #('Soil-File') ].
		spec package: #'Soil-Serializer' with: [  ].		
		spec package: #'Soil-Serializer-Tests' with: [ spec requires: #('Soil-Serializer') ].
		spec package: #'Soil-Core' with: [ spec requires: #('Soil-Serializer' 'Soil-File')  ].
		spec package: #'Soil-Core-Tests' with: [ spec requires: #('Soil-Core') ].
		spec package: #'Soil-Resident' with: [ spec requires: #('Soil-Core') ].
		spec package: #'Soil-Resident-Tests' with: [ spec requires: #('Soil-Resident') ] ].

	spec 
		group: 'tests' with: #('Soil-Core-Tests' 'Soil-File-Tests' 'Soil-Serializer-Tests' 'Soil-Resident-Tests' );
		group: 'default' with: #( 'Soil-Core' 'Soil-Resident' 'tests' ) 
]
