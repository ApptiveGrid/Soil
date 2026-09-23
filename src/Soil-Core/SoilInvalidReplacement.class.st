"
Raised when the naming of a replaced object does not add up: a name registered twice on
the export side, or a name in the stream that the importing side has nothing registered
for.

Both are the same mistake seen from the two ends - the sides did not agree on what the
names are - and both are better found before the import writes anything than after
references have been pointed somewhere wrong.
"
Class {
	#name : #SoilInvalidReplacement,
	#superclass : #SoilError,
	#category : #'Soil-Core-Error'
}
