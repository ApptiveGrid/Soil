Class {
	#name : #SoilFixScaledDecimalMaterializer,
	#superclass : #SoilMaterializer,
	#instVars : [
		'found'
	],
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #accessing }
SoilFixScaledDecimalMaterializer >> found [

	^ found
]

{ #category : #initialization }
SoilFixScaledDecimalMaterializer >> initialize [ 
	super initialize.
	found := false
]

{ #category : #reading }
SoilFixScaledDecimalMaterializer >> nextScaledDecimal: aClass [ 
	| scaledDecimal |
	found := true.
	"materialize scaled decimals the old way to get it loaded. "
	scaledDecimal := aClass new
		                 setNumerator: self nextLengthEncodedInteger
		                 denominator: self nextLengthEncodedInteger
		                 scale: self nextLengthEncodedInteger.
	self registerObject: scaledDecimal.
	^ scaledDecimal
]
