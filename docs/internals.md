

# Support for code changes / refactoring: changes of instance variables

Soil does not store classes but a flat view (a so called BehaviorDescription).

Flat view means that it record the name of the class and all instance variables of the hierarchy. 

Soil operates on *names*, not *offsets*. This the BehavorDesription stores the names of all instance variables of the class itself and all superclasses. (the names that #allInstVarNames returns in Pharo).

This design immediately solves the problem of loading serialized objects after a change of the order of the ivars or even after moving the ivars up and down the hierachy.

If instance variables are removed, the stored values are skipped. If you add new ivars, they are not touched when loading the old objects from disk, but stored with the next commit.

We do not (for now) have any support for renames. Soil sees these as a remove and a new variable, thus the value is lost. See Issue https://github.com/ApptiveGrid/Soil/issues/103 for how this will be solved in the future.

# Support for code changes / refactoring: Class Renames

If you rename a class, you can tell Soil the new name:

```
soil renameClassNamed: #SOMigrationObject to: #SOMigrationObject2.
```

This allows the Soil Materializer to load the old objects into instances of the new class. 

In Pharo12, the support for deprecated aliases can be used alternatively. Add an initalize method on the class side of the new SOMigrationObject2 class (and make sure to call it once):

```
self deprecatedAliases: #(##SOMigrationObject).
```

This will add an alias to the global namespace, Soil will be able to use this alias transparenty to load the old objects.
