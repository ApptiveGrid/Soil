Extension { #name : #Object }

{ #category : #'*Soil-Core' }
Object >> asSoilSignal [ 
	^ SoilSignal on: self 
]

{ #category : #'*Soil-Core' }
Object >> isObjectId [
	^ false
]

{ #category : #'*Soil-Core' }
Object >> isSoilProxy [ 
	^ false
]

{ #category : #'*Soil-Core' }
Object >> soilClusterRootIn: aSOTransaction [ 
	
]

{ #category : #'*Soil-Core' }
Object >> soilEmit [ 
	self asSoilSignal emit
]

{ #category : #'*Soil-Core' }
Object >> soilRecursiveHash [
	^ self soilRecursiveHashWith: (IdentitySet new)
]

{ #category : #'*Soil-Core' }
Object >> soilRecursiveHashWith: aSet [

	"hash calculations are done with bitXor: and that is commutative. So we 
	cannot determine two objects that are exchanged in the graph. By including
	the graph position which is reflected by aSet size we can make the hash 
	position dependent for each object"
	^ (self class classLayout soilRecursiveHash: self with: aSet) bitXor: aSet size * 16r01000193 
]

{ #category : #'*Soil-Core' }
Object >> theNonSoilProxy [
	^ self 
]
