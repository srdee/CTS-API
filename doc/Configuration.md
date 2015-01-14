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
6. [Retrieval Methods](#retrieval-methods)
7. [Credentials](#database-credentials)

##Overview : the configuration file
This CTS-API deployement uses a json file for its configuration. You have to create a config.json at the root of CTS-API installation
```javascript
{
	"db" : {
		"software"	: "existDB",  // Available : existDB
		"version"	: "2.2",
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

**Important note** : in `["repositories"]["resources"]`, you can see that we use the joker `#`. This joker is replaced automatically by the build directory's path. Not using the joker would make opening files not working.

##Examples 
You need to rename those file to config.json.
- [Perseus Digital Library Configuration](../config.perseus.json)


##Database

###Introduction

The database configuration is at the root of the json file. Its key name is `db`.

###Database Software

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
| software      |string|existDB           | The software it will use to run the DB. See [supported database](../README.md#support-informations) in the main README.md
| version       |string|                  | **Soon to be Deprecated** Version of the software you use
| method        |string|url,local,git     | The retrieval method to use. See [Retrieval Methods](#retrieval-methods) for more details
| path          |string|                  | Path from which you need to retrieve your data. Local directory or file, git remote address or url depending on method.
| user          |json  |                  | See [Credentials](#database-credentials)

###Example
This configuration will use eXistDB as a database, retrieving it from sourceforge and will use admin:password as credentials.

```javascript
"db" : {
	"software"	: "existDB", 
	"version"	: "2.2",
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

The repository configuration is at the root of the json file. Its key name is `repositories`. Unlike `db`, its value is a list of json object (formatted `[{}, {}]`). 

###Repository

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|method         |string| local, git, url  | The retrieval method to use. See [Retrieval Methods](#retrieval-methods) for more details
|path           |string|                  | Path from which you need to retrieve your data. Local directory or file, git remote address or url depending on method.
|resources      | list |                  | List of resources object. See below [Resources](#resources)


###Resources

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|name           |string|                  | Identifier for this repository
|texts          |string|                  | The folder's path in which fab will find the texts
|inventory      |string|                  | The Inventory file's path which holds CTS informations
|rewriting_rules| json |                  | Json object. See below [Resources Rewriting Rules](#resources-rewriting-rules)

**Joker character : ** In file path for texts, inventory and rewriting_rules equivalencies, the character `#` can be used to emulate the root of the repository folder when downloaded.

###Resources rewriting rules

Rewriting rules are a set of equivalencies, where `{key1 : value1, key2 : value2}` are helpers to translate database path in the inventory as file path in the downloaded folder. Both key and value should be string. See the example below.

###Example

This repositories example is a set of 1 repository, which we retrieve through `git`. Inside it, we have one inventory, `allcts.xml` which we gave the identifier `canonical_example`. Its texts are found in the folder `#/CTS_XML_TEI/perseus`, where `#` is a joker to the root of the git repository. When browsing the repository, `/db/repository/end/of/path/file.xml` is rewritten and interpreted as `/git-respository/CTS_XML_TEI/perseus/end/of/path/file.xml` through rewriting rules.

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

The remote hosts configuration is at the root of the json file. Its key name is `repositories`. Unlike `db` nor `repositories`, its value is a dictionary of json object (formatted `{"hosts" : { "host_name" : {host json object}, "host_name_2": {host json object}}}`) which are defined below in [Host](#host). 

###Host

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|dumps          |string|                  | Path on the remote server where you whish to store files before they are put in the right folder.
|db             |string|                  | Path where you wish your database software to be installed to on the remote server
|data           |string|                  | Path where you wish your database data to be saved to on the remote server
|user           |json  |                  | See [Credentials](#database-credentials)
|port           |json  |                  | See [Ports](#ports)

**Important notice** : The name of the host should be ssh aliases. Here is a great [tutorial](http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/) about it, but you can look on your favourite search engine as well. I ain't your master, I'm a github page.

###Ports

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|default        |int   |                  | Default port to run the main database on (the public database)
|replicate      |int   |                  | Port to use for testing and deploying new data without interruption of services

###Example

We have one host, named pompei where we can deploy to using `fab set_hosts:pompei deploy` if pompei is a ssh alias. The exist.jar will be put in /home/pompei/dumps while it will be installed in /opt/db and have its data stored in /opt/data. The credential (which have a poor security level as you can see) are admin:password. The public port for the running API will be 8080 while the one we use for tests, rollbacks and deployements is 8090.

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

##Retrieval Methods
There is three retrieval methods available. Retrieval methods defines which service do you want to use to get your database software, text repository, etc. *e.g.* : if you have your texts locally, you might want to just use them instead of downloading it again and again from the web.

- `local` : Retrieve the files from your local computer, given a path such /path/to/my/repository
- `git` : Clone a repository given its https location or its git remote url address
- `url` : Download from an url. e.g. `{"method" : "url", "path" : "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar"}` will download eXist-db-setup-2.2.jar

**Good practice :** While using git or download might be a good practice for production, while you set up your configuration file for the first runs, it's good to test it with `local`. This way, if your configuration file is wrong, you don't have to redownload all the files you needed.

##Database Credentials

| Parameter key | Type | Available Values | Description
|---------------|------|------------------|-------------
|name           |string|                  | Name of the admin user to be used. For eXistDB, it should be admin
|password       |string|                  | Password of the admin user to be used. For security reason, it should not be an empty string