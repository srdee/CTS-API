Capitains Toolkit
=======

## About
As every DH or more generally IT project, we needed a bad joke for the name. Scrambling together CTS and API, we opted out for CAPITainS. We hope you like it.

Capitains Toolkit is providing a CTS API toolkit and python abstraction with built-in function for deployements

## Support informations
**Database**
- eXistDB 2.2
- **Not implemented** baseX

**Retrieval tool**
*Retrieval tools are used to download software or texts.*
- Local copies
- Direct url download
- Git cloning

## Documentation
- [Commands](doc/Commands.md)
- [Configuration](doc/Configuration.md)
- [Code base](doc/Code.md)
- [Roadmap](doc/Roadmap.md)
- [Metadata Design](doc/CTS-Metadata-Design.md)


## Requirements
To be able to use fabfile functions, you will need to install it. You can give a look at [documentation](http://www.fabfile.org/installing.html) or simply do 
```shell
pip install fabric
```
**Warning** : Do not install fabric through `pip3`, as it is for now not `python3` compliant
