# DNA-C Platform API

This repository contains the Cisco DNA-C Platform API v1.2.6 GA and v1.2 EFT as a Postman collection.

Included are:
- `DNA-C_Platform_API_v1.2.6_GA.postman_collection.json` - Postman collection for version 1.2.6 GA (General Availability)
- `DNA-C_Platform_API_v1.2_EFT.postman_collection.json` - Postman collection for version 1.2 EFT (Early Field Trial)
- `DNA-C_Sandbox.postman_environment.json` - Postman environment with credentials to DNA-C sandbox
- `overview-ga.txt` - list of all the endpoints (v1.2.6 GA)
- `overview-eft.txt` - list of all the endpoints (v1.2 EFT)
- `api-ga.txt` - Swagger description of the API v1.2.6 GA
- `api-eft.txt` - description of the API v1.2 EFT in a proprietary format

## How to Use

1. Import both the collection and the environment to your Postman application.
2. Select the "DNA-C Proxy" environment.
3. Send a request depending on the version. Returned token will be added automatically to your environment.
  - (v1.2.6 GA) "Authentication API" request in "Authentication" group
  - (v1.2 EFT) "Get Token" request in "Authentication" group
4. Now you can call the other endpoints.

Note that when working with the sandbox, some requests might be not permitted.

## How to Build

To re-build the collections run:
```bash
./postmanize.sh
```
