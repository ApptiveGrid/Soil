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