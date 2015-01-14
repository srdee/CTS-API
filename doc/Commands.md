CTS Toolkit commands
===

The commands are in no particular order. If you only want to deploy an instance, see [`fab deploy`](#fab-deploy) and the [configuration documentation](./Configuration.md)

##Summary
1.	[Introduction](#introduction)
2.	[Tests](#tests)
  1. [`test_cts`](#fab-test_cts)
3.	[Local Only](#local-only)
  1. [`db_start`](db_start)
  2. [`db_stop`](#fab-db_stop)
  3. [`db_restore`](#fab-db_restore)
  4. [`db_backup`](#fab-db_backup)
  5. [`push_texts`](#fab-push_texts)
  6. [`push_xq`](#fab-push_xq)
  7. [`push_inv`](#fab-push_inv)
  8. [`convert_cts3`](#fab-convert_cts3)
  9. [`clean`](#fab-clean)
4.	[Remote](#remote)
  1. **Important** : [`set_hosts`](#fab-set_hosts)
  2. [`deploy`](#fab-deploy)
  3. rollback
  4. stop
  5. start
  6. restart

##Introduction

###Type of commands
There is three types of commands in the CTS-API Toolkit, which are the following
- Test commands : Test your inventories, xml files, remote server
- Local only commands : Deploy, run, configure and modify local files or instances of the API
- Remote : Deploy, Rollback, Stop or Start the API services

###Commands and parameter
To run command, go in a terminal at the root of this repository (CTS-API). Commands are run after `fab` (e.g. `fab test_cts`). Parameters are separated from `fab` with a colon, their value are set through the equal sign, and each parameter are separated with a comma. Example `fab command:parameter1=value1,parameter2=value2`

##Tests

###fab test_cts

**Definition**

Test your inventories and texts. Tested (as of 14/01/2015) :
- Replication of CitationMapping in XML TEI files (tei:refState)
- Valid XML
- Valid namespace
- Valid citation mapping at all level
- Existing files

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
| nosuccess          | False   | If set to True, successes in tests won't be printed
| ignore_replication | False   | If set to True, replication of CitationMapping in Tei Files tei:refState won't be checked
| no_color			 | False   | If set to True, results won't be color formatted

**Examples**

`fab test_cts:nosuccess=True,no_color=True` will print only failures and warning, without any formatting. You can turn it into a `fab test_cts:nosuccess=True,no_color=True > results.txt` to read the report outside a terminal. 

##Local only

###fab db_start

**Definition**

Start the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | False   | If set to True, start the local database

**Examples**

`fab db_start:localhost=True`

###fab db_stop

**Definition**

Stop the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | False   | If set to True, start the local database

**Examples**

`fab db_stop:localhost=True`

###fab db_restore

**Definition**

Restore the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | False   | If set to True, start the local database
|cts 			     | 5       | Version of the CTS API (3 or 5)

**Examples**
`fab db_restore:cts=3&localhost=True`

###fab db_backup

**Definition**

Make a dump of the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | False   | If set to True, start the local database
|cts 			     | 5       | Version of the CTS API (3 or 5)

**Examples**

`fab db_restore:cts=5`

###fab push_texts

**Definition**

Push texts in corpora to the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | True	   | If set to false, push to an defined environement

**Warning** : This behaviour will be changed soon.

**Examples**



###fab push_xq

**Definition**

Push the XQuery to the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | True	   | If set to false, push to an defined environement
|cts 			     | 5       | Version of the CTS API (3 or 5)

**Warning** : This behaviour will be changed soon.

**Examples**

`fab push_xq:cts=3`

###fab push_inv

**Definition**

Push inventory to the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|localhost			 | True	   | If set to false, push to an defined environement

**Warning** : This behaviour will be changed soon.

**Examples**

`fab push_inv`


###fab convert_cts3

**Definition**



**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|||

**Examples**



###fab clean

**Definition**



**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|||

**Examples**



##Remote

###fab set_hosts

**Definition**



**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|||

**Examples**



###fab deploy

**Definition**



**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|||

**Examples**


