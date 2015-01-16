Capitains Toolkit configuration
===

##Summary
1. [Overview](#overview--the-configuration-file)
2. [Configuration Examples](#examples)
3. [Database Configuration](#database)
  1. [Introduction](#introduction)
  2. [Software](#database-software)
  4. [Example](#example)
4. [Repositories Configuration](#repositories)
  1. [Introduction](#introduction-1)
  2. [Repository](#repository)
  3. [Resources](#resources)
  4. [Resources Rewriting rules](#resources-rewriting-rules)
  5. [Example](#example-1)
5. [Remote Hosts Configuration](#remote-hosts)
  1. [Introduction](#introduction-2)
  2. [Host](#host)
  3. [Ports](#ports)
  4. [Example](#example-2)
6. [Local installation](#localhost-installation)
6. [Retrieval Methods](#retrieval-methods)
7. [Credentials](#database-credentials)

##Overview : the configuration file
To begin create a config.json at the CTS-API installation's root
```javascript
{
	"db" : {
		"software"	: "existDB",  // Available : existDB
		"method"	: "url", // Available : local, url
		"path"		: "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar",  // A url or an absolute path
		"user"		: {
			"name" : "admin",
			"password" : "password"
		}
	},
	"repositories" : [
		"method" : "git",  // Defines which tool to use to retrieve the data. Available : git, local
		"path" : "https://github.com/PerseusDL/canonical.git", // For git, a URL, for local, an absolute path
		"resources" : [
			{
				"name" : "canonical_example" //Name of the collection, optional
				"texts" : "#/canonical/CTS_XML_TEI/perseus",  // The folder in which fab will find the texts
				"inventory" : "#/canonical/CTS_XML_TextInventory/allcts.xml" // The file which holds CTS informations
				"rewriting_rules" : { // Pairs of key, value where key has to be overriden by value in Inventory pointer
					"/db/repository/" : "#/canonical/CTS_XML_TEI/perseus/"
				}
			}
		]
	],
	"hosts" : {
		"hostname" : {
			"dumps" : "/path/to/somewhere/to/upload/some/files",
			"db" : "/path/to/db/software/on/distant/machine",
			"data" : "/path/to/db/data/software",
			"user" : { // For database
				"name" : "admin",
				"password" : "password"
			},
			"port" : {
				"default" : 8080, // Port for the public running database
				"replicate" : 8090 // Port for the replicated database
			}
		}
	}
}
```

**Important note** : in `["repositories"]["resources"]`, notice the `#` character. It is replaced with the build directory's path. If you forget it you can't open files.

##Examples 
You need to rename those file to config.json.
- [Perseus Digital Library Configuration](../config.perseus.json)


##Database

###Introduction

The database configuration is at the root of the json file. Its key name is `db`.

###Database Software

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
| software      |string|existDB           | Name of supported database software. See [supported database](../README.md#support-informations)| method        |string|url,local,git     | The retrieval method to use. See [Retrieval Methods](#retrieval-methods) for more details
| path          |string|                  | Path to your data. It can be a local directory or file, git remote address, or url depending on method.
| user          |json  |                  | See [Credentials](#database-credentials)

###Example
This configuration will use eXistDB as the database, retrieving it from sourceforge and use admin:password as credentials.

```javascript
"db" : {
	"software"	: "existDB", 
	"method"	: "url",
	"path"		: "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar",
	"user"		: {
		"name" : "admin",
		"password" : "password"
	}
}
```
##Repositories

###Introduction

The repository configuration is at the root of the json file. Its key name is `repositories`. Unlike `db`, its value is an array of json objects ( `[{}, {}]`). 

###Repository

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|method         |string| local, git, url  | The retrieval method to use. See [Retrieval Methods](#retrieval-methods) for more details
|path           |string|                  | Path to your data. It can be a local directory or file, git remote address or url depending on method.
|resources      | list |                  | List of resources. See below [Resources](#resources)


###Resources

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|name           |string|                  | Identifier for this repository
|texts          |string|                  | The path fab uses to retrieve texts
|inventory      |string|                  | The path to the Inventory file, which holds CTS information
|rewriting_rules| json |                  | Json object. See [Resources Rewriting Rules](#resources-rewriting-rules)

**Joker character : ** In file path for texts, inventory and rewriting_rules equivalencies, the `#` character can be used to map to the root of the repository, similar to how `~` maps to your home directory in BASH.

###Resources rewriting rules

Rewriting rules are a set of equivalencies, where `{key1 : value1, key2 : value2}` translate database paths in the inventory to file paths in the downloaded folder. Both key and value must be strings. See the example below.

###Example

This repositories config example shows how to retrieve a single repository with `git`. Notice we have one inventory, `allcts.xml`, which we gave the identifier `canonical_example`. Its texts are found in the folder `#/CTS_XML_TEI/perseus`.  Notice we're using `#` to map to the root of the git repository. When browsing the repository, `/db/repository/end/of/path/file.xml` is rewritten and interpreted as `/git-respository/CTS_XML_TEI/perseus/end/of/path/file.xml` through rewriting rules.

```javascript
"repositories" : [
	"method" : "git",
	"path" : "https://github.com/PerseusDL/canonical.git", 
	"resources" : [
		{
			"name" : "canonical_example" 
			"texts" : "#/CTS_XML_TEI/perseus",
			"inventory" : "#/CTS_XML_TextInventory/allcts.xml" 
			"rewriting_rules" : {
				"/db/repository/" : "#/CTS_XML_TEI/perseus/"
			}
		}
	]
],
```
##Remote hosts

###Introduction

The remote hosts configuration is at the root of the json file. Its key name is `repositories`. Unlike `db` and `repositories`, its value is a json object (formatted `{"hosts" : { "host_name" : {host json object}, "host_name_2": {host json object}}}`) which are defined below in [Host](#host). 

###Host

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|dumps          |string|                  | Path on the remote server to store files before they are put in the right folder.
|db             |string|                  | Path on the remote server to install the database software 
|data           |string|                  | Path on the remote server to save database data
|user           |json  |                  | See [Credentials](#database-credentials)
|port           |json  |                  | See [Ports](#ports)

**Important notice** : The name of the host must be an ssh aliases. Here is a [tutorial](http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/) about it, but you can look on your favourite search engine as well. I ain't your master, I'm a github page.

###Ports

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|default        |int   |                  | The main database's (the public database) default port
|replicate      |int   |                  | Database port used to test and deploy new data without service interruption

###Example

We have one host named pompei that is configured and ready to deploy.

```javascript
"hosts" : {
	"pompei" : {
		"dumps" : "/home/pompei/dumps",
		"db" : "/opt/db/",
		"data" : "/opt/data/",
		"user" : {
			"name" : "admin",
			"password" : "password"
		},
		"port" : {
			"default" : 8080, 
			"replicate" : 8090
		}
	}
}
```

If pompei is a ssh alias we can deploy the database using `fab set_hosts:pompei deploy`, exist.jar will be put in /home/pompei/dumps, installed in /opt/db, and its data is stored in /opt/data. 
The database access credentials (which as you can see aren't very secure) are admin:password.
API's public port is 8080.  The other port, 8090, we use for tests, rollbacks and deployements.

##Localhost installation

The local host configuration is at the root of the json file. Its key name is `localhost`.

**Parameters**

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|db             |string|                  | Path on the local server to install the database software 
|data           |string|                  | Path on the local server to save database data
|user           |json  |                  | See [Credentials](#database-credentials)
|port           |int   |                  | Port on which to run your database

**Example**

```javascript
"localhost" : {
	"db" : "~/cts-api/db",
	"data" : "~/cts-api/data",
	"user" : {
		"name" : "admin",
		"password" : "password"
	},
	"port" : 8080
}
```

The following configuration will install the software in ~/cts-api/db and put the data in ~/cts-api/data

##Retrieval Methods
There is three retrieval methods available. They define how you will connect to your database software, text repository, etc. If your texts are stored locally, use `local` instead of the others so you aren't repeatedly downloading them from the web.

- `local` : Retrieve local files stored in a given path `/path/to/my/repository`
- `git` : Clone a repository using its https location or its git remote url address
- `url` : Download from an url. e.g. `{"method" : "url", "path" : "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar"}` will download eXist-db-setup-2.2.jar

**Good practice :** Using `git` or `url` may be better for production, but while you are still configuring your installation it's best to test it with `local`. This way if your configuration file is wrong, you won't waste time redownloading all the files.

##Database Credentials

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|name           |string|                  | Name of the admin user. For eXistDB, it should be admin
|password       |string|                  | The admin user's password. For security reason, it should not be an empty string
