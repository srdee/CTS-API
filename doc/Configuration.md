Captains Toolkit configuration
===

##Summary
1. [Overview](#overview--the-configuration-file)
2. [Configuration Examples](#examples)
3. [Database Configuration](#database)
  1. [Introduction](#introduction)
  2. [Software](#database-software)
  3. [Credentials](#database-credentials)
  4. [Example](#example)
4. [Repositories Configuration](#repositories)
  1. [Introduction](#introduction-1)
  2. [Resources](#resources)
  3. [Resources Rewriting rules](#resources-rewriting-rules)
  4. [Example](#example-1)
5. [Remote Hosts Configuration](#remote-hosts)
  1. [Introduction](#introduction-2)
  2. [Credentials](#database-credentials-1)
  3. [Ports](#ports)
  4. [Example](#example-2)
6. [Retrieval Methods](#retrieval-methods)

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

###Database Software

###Database Credentials

###Example

##Repositories

###Introduction

###Resources

###Resources rewriting rules

###Example

##Remote hosts

###Introduction

###Database Credentials

###Ports

###Example

##Retrieval Methods
There is three retrieval methods available. Retrieval methods defines which service do you want to use to get your database software, text repository, etc. *e.g.* : if you have your texts locally, you might want to just use them instead of downloading it again and again from the web.

- `local` : Retrieve the files from your local computer, given a path such /path/to/my/repository
- `git` : Clone a repository given its https location or its git remote url address
- `url` : Download from an url. e.g. `{"method" : "url", "path" : "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar"}` will download eXist-db-setup-2.2.jar

**Good practice :** While using git or download might be a good practice for production, while you set up your configuration file for the first runs, it's good to test it with `local`. This way, if your configuration file is wrong, you don't have to redownload all the files you needed.