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
					"texts" : "./canonical/CTS_XML_TEI/perseus",  // The folder in which fab will find the texts
					"inventory" : "./canonical/CTS_XML_TextInventory/allcts.xml" // The file which holds CTS informations
				}
			]

		]
}
```

## What the deployement steps should include
The fabfile should do the following things :
- Download or ensure that resources are available, wether it's **text** or **software**
- Ensure text and inventory are CTS compliant
- Ensure text and inventory holds right informations
- Index the data
- Push to a server using zip
- Unzip on the server
- Ensure version rollback possibilites using symlink and reducing downtime 
- Do some tests

##Deployement command
`fab deploy`