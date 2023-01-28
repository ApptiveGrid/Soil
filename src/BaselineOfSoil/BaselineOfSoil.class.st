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
		spec package: #'Soil-Core-Tests' with: [ spec requires: #('Soil-Core') ] ].

	spec 
		group: 'tests' with: #('Soil-Core-Tests' 'Soil-File-Tests' 'Soil-Serializer-Tests' );
		group: 'default' with: #( 'Soil-Core' 'tests' ) 
]

{ #category : #'as yet unclassified' }
BaselineOfSoil >> fuel: spec [
	
	spec baseline: 'Fuel' with: [ 
		spec 
			repository: 'github://ApptiveGrid/Fuel:development/repository']
]
