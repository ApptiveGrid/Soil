# Controlling the lifecycle of a database instance

Soil stores its data on the local filesystem. The equivalent of the soil database instance in memory is a directory on a filesystem. This directory and everything beneath is controlled by soil. 

So the basic association we need to do is to associate the in-memory represenation with the directory on the filesystem by doing 

```
soil := Soil path: 'mydb'.
```

From here there are multiple options:

## Creating a database 

Before you can work with soil you need to create an instance. 

```
soil := Soil path: 'mydb'.
soil initializeFilesystem 
```

The method #initializeFilesystem creates the directory mydb and creates some files/directories beneath it. This is the basic structure soil needs to operate. After calling #initializeFilesystem the variable soil holds a fully initialized and functional database instance. 

The equivalent short form of the code above is 

```
soil := Soil createOnPath: 'mydb'
```

Trying to create a database on a non-empty directory will throw an error. So soil will not overwrite a prior existing database instance

# Opening a database 

An existing soil instance can be opened with 

```
soil := Soil path: 'mydb'.
soil open 
```

or with the short form 

```
soil := Soil openOnPath: 'mydb'
```

# Closing a database 

When the soil instance is not used anymore it should be closed to free the open file streams and such. For this a simple 

```
soil close
```

does that. 

# Deleting a database

You can delete soil in programmatical way using 

```
soil destroy
```

this will delete the directory of the soil instance. For testing purposes it might be useful to start over with always a new instance. You can combine it this way

```
soil := (Soil path: 'mydb')
   destroy;
   initializeFilesystem.
```

Now every time this is executed it will delete the soil instance and recreate it from scratch

# Controlling access

Soil keeps commits consistent on its own: one commit at a time within an image (a semaphore), and fcntl range locks on the files while a commit writes. Who may use a database at all is a separate matter, and there are three levels for it. They differ in how far they reach and in what happens when the one who set them dies.

| level | keeps out | reaches | ends when | refusal |
|---|---|---|---|---|
| owner lock (`owner.lock`) | every other process | across processes | `#unlockExclusive`, `#close`, or the process dies | `SoilDatabaseOwned`, with the owner |
| gate | new transactions and commits of every other process in the image | the image | `#openGate`, or the closing process dies | `SoilGateClosed` |
| maintenance marker (`maintenance.lock`) | opening the database | across processes and restarts | somebody removes the file | `SoilDatabaseInMaintenance` |

## Owner lock

A process claims a database with

```
soil lockExclusiveAs: 'host-a:8080'
```

and writes who it is into `owner.lock`. Another process that tries gets `SoilDatabaseOwned`, and its `#owner` is what the first one wrote: an endpoint to forward a request to, for instance. `#lockExclusive` writes `#ownerDescription` instead. The claim ends with `#unlockExclusive` or `#close`; the file is emptied, not deleted.

The lock belongs to the process, not to the stream: if the owning process opens `owner.lock` a second time and closes it, the claim is gone. Read the owner from another process only.

## Gate

```
soil gateDo: [ ... ]
soil drainedGateWithin: 30 seconds do: [ ... ]
```

`#gateDo:` closes the gate for the duration of the block: other processes of the image get no new transactions and cannot commit, while transactions they have open can still read. `#drainedGateDo:` and `#drainedGateWithin:do:` also wait until no other transaction is open, and fail with `SoilDatabaseBusy` if that does not happen in time. The process that closed the gate uses the database as usual. `#garbageCollect` closes the gate by itself, or runs under the caller's.

## Maintenance marker

```
touch mydb/maintenance.lock
```

As long as the file is there, `#open` fails with `SoilDatabaseInMaintenance`. It is meant to be set from the outside while the database is closed, and it stays across crashes and restarts until somebody removes it. A database that is open already is not affected. The one who does the maintenance opens it with `#openForMaintenance`.
