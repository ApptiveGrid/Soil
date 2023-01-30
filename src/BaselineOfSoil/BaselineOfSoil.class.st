"
Baseline for Soil OO database [https://github.com/ApptiveGrid/Soil](https://github.com/ApptiveGrid/Soil)
"
Class {
	#name : #BaselineOfSoil,
	#superclass : #BaselineOf,
	#category : #BaselineOfSoil
}

{ #category : #baselines }
BaselineOfSoil >> baseline: spec [
	<baseline>

	spec for: #'common' do: [
		"Packages"
		spec
			package: #'Soil-File';
			package: #'Soil-File-Tests' with: [ spec requires: #('Soil-File') ];

			package: #'Soil-Serializer';
			package: #'Soil-Serializer-Tests' with: [ spec requires: #('Soil-Serializer') ];

			package: #'Soil-Core' with: [ spec requires: #('Soil-Serializer' 'Soil-File') ];
			package: #'Soil-Core-Tests' with: [ spec requires: #('Soil-Core') ].

		"Groups"
		spec
			group: 'Core' with: #('Soil-Core');
			group: 'Tests' with: #('Soil-Core-Tests' 'Soil-File-Tests' 'Soil-Serializer-Tests' );
			group: 'CI' with: #('Tests');
			group: 'all' with: #( 'Core' 'Tests' );
			group: 'default' with: #( 'all' ) ]
]

{ #category : #other }
BaselineOfSoil >> fuel: spec [

	spec baseline: 'Fuel' with: [
		spec
			repository: 'github://ApptiveGrid/Fuel:development/repository']
]
