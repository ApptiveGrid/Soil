Class {
	#name : #BaselineOfSoil,
	#superclass : #BaselineOf,
	#category : #BaselineOfSoil
}

{ #category : #baselines }
BaselineOfSoil >> baseline: spec [
	<baseline>

	spec for: #'common' do: [
		spec package: #'Soil-Core' with: [  ].
		spec package: #'Soil-Core-Tests' with: [ spec requires: #('Soil-Core') ] ].

	spec 
		group: 'default' with: #( 'Soil-Core' 'Soil-Core-Tests' ) 
]

{ #category : #'as yet unclassified' }
BaselineOfSoil >> fuel: spec [
	
	spec baseline: 'Fuel' with: [ 
		spec 
			repository: 'github://ApptiveGrid/Fuel:development/repository']
]
