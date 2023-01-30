"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestSoilSerializerTests,
	#superclass : #PackageManifest,
	#category : #'Soil-Serializer-Tests-Manifest'
}

{ #category : #'code-critics' }
ManifestSoilSerializerTests class >> ruleFloatReferencesRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#'Soil-Serializer-Tests')) #'2023-01-31T00:47:53.850026+01:00') )
]
