CTS Toolkit commands
===

The commands are in no particular order. If you only want to deploy an instance, see [`fab deploy`](#fab-deploy) and the [configuration documentation](./Configuration.md)

##Summary
1.	[Introduction](#introduction)
2.	[Tests](#tests)
3.	[Local Only](#local-only)
4.	[Remote](#remote)

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

##Remote