Capitains Toolkit commands
===

The commands are in no particular order. If you only want to deploy an instance, see [`fab deploy`](#fab-deploy) and the [configuration documentation](./Configuration.md)

##Summary
1. [Introduction](#introduction)
2. [Tests](#tests)
  1. [`test_cts`](#fab-test_cts)
3. [Local Only](#local-only)
  1. [`convert_cts3`](#fab-convert_cts3)
  2. [`clean`](#fab-clean)
  3. [`push_texts`](#fab-push_texts)
  4. [`push_xq`](#fab-push_xq)
  5. [`push_inv`](#fab-push_inv)
4. [Local and Remote](#local-and-remote)
  1. **Important** : [`set_hosts`](#fab-set_hosts)
  2. **Important** : [`localhost`](#fab-localhost)
  3. [`deploy`](#fab-deploy)
  4. [`db_start`](#fab-db_start)
  5. [`db_stop`](#fab-db_stop)
  6. [`db_restart`](#fab-db_restart)
  7. [`db_restore`](#fab-db_restore)
  8. [`db_backup`](#fab-db_backup)
4. [Remote](#remote)
  1. [`available_versions`](#fab-available_versions)
  2. [`rollback`](#fab-rollback)

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
| no_color           | False   | If set to True, results won't be color formatted

**Examples**

`fab test_cts:nosuccess=True,no_color=True` will print only failures and warning, without any formatting. You can turn it into a `fab test_cts:nosuccess=True,no_color=True > results.txt` to read the report outside a terminal. 

##Local only

###fab push_texts

**Definition**

Push texts in corpora to the database. Requires localhost prefix

**Examples**

`fab localhost push_texts`

###fab push_xq

**Definition**

Push the XQuery to the database. Requires localhost prefix

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|cts 			           | 5       | Version of the CTS API (3 or 5)

**Warning** : This behaviour will be changed soon.

**Examples**

`fab localhost push_xq:cts=3`

###fab push_inv

**Definition**

Push inventory to the database. Requires localhost prefix

**Examples**

`fab localhost push_inv`

###fab convert_cts3

**Definition**

Convert CTS3 Inventory to CTS5

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|copy                | True    | Path where you wish to save converted inventories.

**Examples**

`fab convert_cts3:copy="/home/username/Documents/` will save every converted inventories in `/home/username/Documents/`

`fab convert_cts3` wil save it in the `build` folder of your Capitains Toolkit folder root

###fab clean

**Definition**

Clean the building dir in case something went wrong.

**Examples**

`fab clean`

##Local and remote

###fab set_hosts

**Definition**

Set host to which the remote commands should be sent to, referring to the json config file config.json["hosts"]["hostname"]

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
| host               | -       | Name of the host

**Examples**

As this function as no default and one parameter, you can run it without naming the parameter `fab set_hosts:hostname`. Through, this function does nothing by itself, so you need to put something after it.

###fab localhost

**Definition**

Set the local machine as the destination for the database and the API. As `set_hosts:hostname`, this is only a prefix function which should be followed by an action to take.

###fab deploy

**Definition**

Deploy the CTS-API and its text to a given host

**Parameters**

| Parameter          | Default 		  | Description 
|--------------------|----------------|-------------
|convert 		       	 | True   		  | If set to False, does not convert cts3 to cts5
|localhost	    		 | False  		  | 

**Examples**

`fab set_host:host_name deploy:convert=False`


###fab db_start

**Definition**

Start the database, *eg* : `fab localhost db_start` will start your database locally

###fab db_stop

**Definition**

Stop the database, *eg* : `fab set_hosts:pompei db_stop` will start your database remotely on host pompei

###fab db_restart

**Definition**

Retart the database, *eg* : `fab localhost db_restart` will restart your database locally

###fab db_restore

**Definition**

Restore the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|cts                 | 5       | Version of the CTS API (3 or 5)
|source_dir          |         | Path to folder where dumps can be found

**Examples**
`fab localhost db_restore:cts=3`

###fab db_backup

**Definition**

Make a dump of the database

**Parameters**

| Parameter          | Default | Description 
|--------------------|---------|-------------
|cts                 | 5       | Version of the CTS API (3 or 5)
|version             |         | Version of the database to backup, by default, the last installed

**Examples**

`fab set_hosts:pompei db_backup:cts=5`

##Remote

###fab available_versions

Given a remote host, list all available version for backup and rollback

**Example**:

`fab set_hosts:pompei available_versions`

###fab rollback

Placeholder
