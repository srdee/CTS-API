CTS-API Toolkit configuration
===

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

## Examples 
- [Perseus Digital Library Configuration](../config.perseus.json)