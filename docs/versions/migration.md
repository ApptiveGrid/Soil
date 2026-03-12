# Soil database format migration 

## v4

We did a non-backward compatible change to indexes which needs to migrate the databases. Indexes so far had only forward pointer to pages in there internal structure. For multiple reasons we decided that adding backward pointers is an improvement over the current situation.

To migrate your database you just need to call the following 

```
(Soil path: '/path/to/soil/database/directory')`
	`migrateDatabaseFormat` 
```

This will scan the whole database and converts all indexes found
## upgrading v1, v2 and v3

These version do not need to be migrated. There are changes in the way indexes work but these are backward compatible in a way that old indexes still work and new ones are created in a new format 
