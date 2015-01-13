CTS-API Toolkit Roadmap
===

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