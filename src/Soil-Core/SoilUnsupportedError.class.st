"
Raised where Soil meets something it can hold but not do: a structure, a value or a
combination that is legal to store and has no place in the operation at hand.

There is one class for all of these on purpose. What the caller needs is the sentence,
not a class name to catch - the alternative is a new subclass per site, and a family of
them says no more than a good messageText does. Signal it with #signal: and name both
what was met and what could not be done with it.
"
Class {
	#name : #SoilUnsupportedError,
	#superclass : #SoilError,
	#category : #'Soil-Core-Error'
}
