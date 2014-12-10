CTS-API
=======

Providing a CTS API with built in function for deployements

#Fab deployement

##Requirements
To be able to use fabfile functions, you will need to install it. You can give a look at [documentation](http://www.fabfile.org/installing.html) or simply do 
```shell
pip install fabric
```
**Warning** : Do not install fabric through `pip3`, as it is for now not `python3` compliant

##Configuration file
This CTS-API deployement uses a json file for its configuration. 
```javascript
{
	"db" : {
		"software"	: "existDB",  // Available : existDB
		"version"	: "2.2",
		"source"	: "url", // Available : local, url
		"path"		: "http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar"  // A url or an absolute path
	},
	"repositories" : {
		"canonical_example" : {
			"source" : "git",  // Defines which tool to use to retrieve the data. Available : git, local
			"path" : "https://github.com/PerseusDL/canonical.git", // For git, a URL, for local, an absolute path
			"ressources" : [
				{
					"texts" : "./CTS_XML_TEI/perseus",  // The folder in which fab will find the texts
					"inventory" : "./CTS_XML_TextInventory/allcts.xml" // The file which holds CTS informations
				}
			]

		}
	}
}
```