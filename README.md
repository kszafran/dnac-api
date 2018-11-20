# DNA-C Platform API v1.2 EFT

This repository contains the Cisco DNA-C Platform API v1.2 EFT as a Postman collection.

Included are:
- DNA-C_Platform_API_v1.2_EFT.postman_collection.json - Postman collection
- DNA-C_Sandbox.postman_environment.json - Postman environment with credentials to DNA-C sandbox
- overview.txt - list of all the endpoints

## How to Use

1. Import both the collection and the environment to your Postman application.
2. Select the "DNA-C Proxy" environment.
3. Send the "Get Token" request in "Authentication" group. Returned token will be added automatically to your environment.
4. Now you can call the other endpoints.

Note that when working with the sandbox, some requests might be not permitted.

## How to Build

To re-build the collection run:
```bash
./postmanize.sh
```
