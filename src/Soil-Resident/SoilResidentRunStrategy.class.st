"
When a resident's next work unit is due -- and nothing else.

I am a separate object from the resident because cadence and purpose vary
independently. What a resident is for says nothing about whether it runs on a
clock, on a signal, or on a signal followed by a collecting window; and one
cadence serves residents that have nothing else in common. Kept apart, that is
two small hierarchies instead of their cross product.

What I must not do is decide anything about his life. The process, the loop, the
cooperative stop and its receipt are his. I only block until it is time.

And I never read the database. The one thing I may ask him is #hasPendingWork,
and that is a flag he maintains, not a question put to storage -- see
SoilActiveResident on why that distinction is not a detail.
"
Class {
	#name : #SoilResidentRunStrategy,
	#superclass : #Object,
	#instVars : [
		'resident'
	],
	#category : #'Soil-Resident'
}

{ #category : #waiting }
SoilResidentRunStrategy >> awaitDue [
	"block until the next step is due. I may also return because the resident was
	asked to stop -- his loop checks that itself, right after I return"
	self subclassResponsibility
]

{ #category : #accessing }
SoilResidentRunStrategy >> resident [
	^ resident
]

{ #category : #accessing }
SoilResidentRunStrategy >> resident: aResident [
	resident := aResident
]
