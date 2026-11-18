Extension { #name : #SoilBehaviorDescription }

{ #category : #'*Soil-Serializer' }
SoilBehaviorDescription >> compatibilityCheck: aClassLayout [

	"we can read if the layout is the same"
	classLayout == aClassLayout class name ifTrue: [ ^true ].
	"we support turning variable objects into fixed onces (and vice versa)"
	(self isVariableLayout and: [ aClassLayout isFixedLayout]) ifTrue: [ ^true ].
	(aClassLayout isVariable and: [ aClassLayout isBits not and: [self isFixedLayout]]) ifTrue: [ ^true ].
	"for now we raise errors for the others. We could instead create and empty object and log a warning"
	SoilLayoutMigrationError signal: 'Incompatible layout detected: trying to read a ', classLayout , ' current code uses ', aClassLayout class name asString
]
