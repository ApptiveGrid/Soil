Extension { #name : #SequenceableCollection }

{ #category : #'*Soil-Core' }
SequenceableCollection >> isEqualTo: otherCollection [ 
	| size |
	(otherCollection isKindOf: SequenceableCollection) ifFalse: [^ false].
	(size := self size) == otherCollection size ifFalse: [^ false].
	1 to: size do:
		[:index |
		((self at: index) isEqualTo: (otherCollection at: index)) ifFalse: [^ false]].
	^ true
]
