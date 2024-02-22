# Soil 

1. [initial plan](initial-plan.md)

# 2. Basic Usage

A simple example for the most basic usage. We have the data that we want to store pointed to by the "yourModelRoot":

```
db := Soil path: ‚mydb‘.
db initializeFilesystem.
txn := db newTransaction.
txn root: yourModelRoot.
txn commit.
```

it will save the whole object graph pointed to by youModelRoot the database. Every time you do 

```
txn := db newTransaction.
txn root
```

it will read all of the model you have just write now but concurrent safe.

Optimizing this is partitioning your graph and saying which of your objects are standalaone by saying

```
txn makeRoot: anObject.
```

then only the needed parts of your model are loaded. But in order to save it you have to mark the objects you made root dirty by saying

```
txn markDirty: anObject
```
That‘s all for basic usage. 

# Support for code changes / refactoring: changes of instance variables

Soil does not store classes but a flat view (a so called BehaviorDescription).

Flat view means that it record the name of the class and all instance variables of the hierarchy. 

Soil operates on *names*, not *offsets*. This the BehavorDesription stores the names of all instance variables of the class itself and all superclasses. (the names that #allInstVarNames returns in Pharo).

This deseign immediatly solves the problem of loading serialized objects after a change of the order of the invars or even after moving the ivars up and down the hierachy.

If instane variables are removed, the stored values is skipped. If you add new ivars, they are not touched when loading the old objects from disk, but stored with the next commit.

We do not (for now) have any support for renames. Soil sees these are a remove and a new variable, thus the value ist lost. See Issue https://github.com/ApptiveGrid/Soil/issues/103 for how this will be solved in the future.

# Support for code changes / refactoring: Class Renames

If you rename a class, you can tell Soil the new name:

```
soil renameClassNamed: #SOMigrationObject to: #SOMigrationObject2.
```

This allows the Soil Materializer to load the old objects into instances of the new class. 
