Extension { #name : #UndefinedObject }

{ #category : #'*Soil-Core' }
UndefinedObject >> objectWithId: aSoilObjectId [ 
	"there are cases where the transaction of a soil proyx is
	unreachable/unset. In those cases it raises an exception 
	within the processing in the ProtoObject which locks up 
	the system because the debugger triggers the same error
	over and over again. So in case the proxy resolves on a 
	nil transaction we return an unresolved Object here so it
	can be debugged"
	^ SoilUnresolvedProxy objectId: aSoilObjectId 
]
