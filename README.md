# Soil

Soil aims to be a lightweight OO database for pharo that supports ACID transactions. It will utilize MVCC for concurrency control and history management of data.

This project is at its very start and we are in exploration phase about the things we need.

## Clustering/partitioning

An OO database should be able to store an arbitrary object graph to a persistent medium and also be able to read it back. To do this in an efficient manner the graph is not stored as a whole but as clusters/partitions.
Creating cluster is the responsibility of the code using the database. A simple call like

```
transaction makeRoot: anObject
```

should be sufficient to mark any object as a cluster root. When the graph is serialized to disk all references to a cluster root are replaced by a proxy object pointing to that cluster and the cluster itself is serialized separately.
For this to work clusters need to be **discoverable**. Each cluster gets a clusterId on the storage medium to be able to retrieve it. The proxy that replaces a cluster root on serialization holds the cluster id of the referenced cluster to load dynamically.

When a transaction is written to disk, a graph is serialized to bytes that get stored. Pharo already includes a very good object serializer: **Fuel**. We use **Fuel** to serialize the sliced clusters to disk and bigger part of the database is already in place.

__note:__ Proxies are serialized with Fuel means that the information about references to other clusters is encoded within Fuel. We need a way to have that information on a lower level in order to traverse the structure without having the need to materialize everything

## MVCC

MVCC stands for __multi version concurrency control__ and is the way many modern databases treat concurrency. MVCC never changes a written object on disk. It always creates a new version of the object which is appended to the store the objects live in. Each version is tagged with a timestamp or sequencial id. When a transaction is created it also creates a timestamp and only ready object versions that have the same timestamp or one that is older. This way consequent reads from the database always get the state at that particular time. Writes of objects to the store are invisible to a transaction if they are written after the transaction has been created. Maintaing a read timestamp in a transaction also raises conflicts when the read timestamp and the actual timestamp of the object in the store differ

# file locking

When data is written to the disk, e.g. appending a new version of an object to the store, the necessary structures are locked on disk. This is done by using regional locking capabilities of the underlaying operating system. Regional locking sets a lock to a region of bytes in a file with offset and length. This way multiple non-conflicting locks can be made to the same file. In other databases this is usually called row level locking. Functionality for this file locking is already implemented using **unifiedFFI*** to access the **fcntl*** system call which provides the regional locking

# garbage collection

Especially when using MVCC it is important to have garbage collection. As on every write a new version of a cluster is written to disk there will be a lot of old versions floating around making the database grow on each change. In postgres this is called vacuuming. The GC walks the connected graph and copies does clusters over to a new file. The old file containing the objects is deleted at the end which removes all the old versions. It works in a way a simple mark&sweep algorithm does it
