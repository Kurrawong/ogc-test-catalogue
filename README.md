# OGC Test Catalogue

This repository houses some example data to use during development of prez/prez-ui improvements for the OGC OSPD 2025.

The main goals are:
- display ontologies as comprehensive as possible in prez, not just their metadata
- display OGC building blocks
- display provenance information

This repository is meant to be used as a backend to prez-ui, and assumes you have a separate instance of prez-ui running, configured to connect to http://localhost:8000 for the backend.

## Running the test server

To start with a clean db, run the following script to remove any remaining fuseki files:
```
cd server
./clear-fuseki-db.sh
```

Run fuseki by running (in the `server` directory):

```
task up
```

Once the server is up, datasets can be created, such as the test dataset in `./data/dataset-config.ttl`. (`uv tool install kurra`)

```
kurra db create http://localhost:3030 --config ../config/dataset-config.ttl
```

You'll see a warning in the docker logs of the `fuseki` service:

```
WARN  GeoAssembler    :: Dataset empty. Spatial Index not constructed. Server will require restarting after adding data and any updates to build Spatial Index.
```

We need some data to display. For this, we can use prezmanifest (`uv tool install prezmanifest`):
(the options specify to only update the DB, not the local files)

```
pm sync ../manifest.ttl http://localhost:3030/ogc-test-catalogue/ True False True False
```

Upload the custom endpoint configuration for the prez instance:
```
kurra db upload ../config/prez-endpoints.ttl http://localhost:3030/ogc-test-catalogue -g http://prez-system
```

As well as some custom prefixes for the catalogue to display properly:
```
kurra db upload ../config/prefixes.ttl http://localhost:3030/ogc-test-catalogue -g http://prez-system
```

We can also add custom Prez Profiles to improve listings:

```
kurra db upload ../config/profiles.ttl http://localhost:3030/ogc-test-catalogue -g http://prez-system
```

Finally, restart the fuseki and prez instances so the geospatial index gets built and the prez endpoints get loaded.

```
task rs
```

Check the logs to see if the prez endpoint configuration was loaded correctly:

```
docker compose logs -f prez
```

If you see the following, the endpoints were loaded correctly:

```
prez-1  | 2025-11-10 10:17:09.648 [INFO] prez: Starting up
prez-1  | 2025-11-10 10:17:09.660 [INFO] prez.services.app_service: Checking SPARQL endpoint http://fuseki:3030/ogc-test-catalogue is online
prez-1  | 2025-11-10 10:17:11.022 [INFO] prez.services.app_service: Successfully connected to triplestore SPARQL endpoint
prez-1  | 2025-11-10 10:17:11.083 [INFO] prez.services.app_service: 1 prefixes bound from data repo
prez-1  | 2025-11-10 10:17:11.088 [INFO] prez.services.app_service: 8 prefixes bound from file standard.ttl
prez-1  | 2025-11-10 10:17:11.178 [INFO] prez.services.app_service: Generating prefixes for 417 IRIs.
prez-1  | 2025-11-10 10:17:11.197 [INFO] prez.services.app_service: Generated prefixes for 417 IRIs. Skipped 0 IRIs.
prez-1  | 2025-11-10 10:17:11.207 [INFO] prez.services.app_service: No remote template queries found
prez-1  | 2025-11-10 10:17:11.227 [INFO] prez.services.app_service: No remote Jena FTS shapes found
prez-1  | 2025-11-10 10:17:11.248 [INFO] prez.services.generate_profiles: Prez default profiles loaded
prez-1  | 2025-11-10 10:17:11.265 [INFO] prez.services.generate_profiles: No remote profiles found
prez-1  | 2025-11-10 10:17:11.333 [INFO] prez.services.app_service: Remote endpoint definitions found and added for type https://prez.dev/ont/DynamicEndpoint
prez-1  | 2025-11-10 10:17:11.351 [INFO] prez.services.app_service: No remote endpoint definitions found for type https://prez.dev/ont/OGCFeaturesEndpoint
prez-1  | 2025-11-10 10:17:11.369 [INFO] prez.services.app_service: Populated API info
prez-1  | 2025-11-10 10:17:11.376 [INFO] prez.services.app_service: No remote queryable definitions found
prez-1  | 2025-11-10 10:17:11.376 [INFO] prez.services.app_service: No local queryable definitions found
prez-1  | 2025-11-10 10:17:11.449 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}
prez-1  | 2025-11-10 10:17:11.454 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}
prez-1  | 2025-11-10 10:17:11.460 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}
prez-1  | 2025-11-10 10:17:11.466 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}/objects/{objectId}
prez-1  | 2025-11-10 10:17:11.479 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs
prez-1  | 2025-11-10 10:17:11.492 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items
prez-1  | 2025-11-10 10:17:11.504 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections
prez-1  | 2025-11-10 10:17:11.517 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}/objects

```

If you don't see any dynamic routes added, upload the custom endpoint configuration again and restart:

```
kurra db upload ../config/prez-endpoints.ttl http://localhost:3030/ogc-test-catalogue -g http://prez-system
task prez-rs
```


## Understanding the prez custom endpoint configuration

In `./config/prez-endpoints.ttl`, you'll find custom definitions for the /items endpoints for ontologies.

```
# Items Endpoints
# --------------
ex:items-listing
    a ont:DynamicEndpoint, ont:ListingEndpoint ;
    rdfs:label "Items Listing" ;
    ont:apiPath "/catalogs/{catalogId}/collections/{recordsCollectionId}/items" ;
    ont:relevantShapes ex:shape-R0-HL3, ex:shape-R0-HL3-1, ex:shape-R0-HL3-2, ex:shape-R0-HL3-ontology-terms .
```

The `ex:shape-R0-HL3-ontology-terms` definition here specifies the path from the terms (classes and properties) in ontologies to the ontology description itself, as well as the path all the way to the catalog the ontology is part of.

```
# Level 3: Ontology classes and properties
# ----------------------------------------
ex:shape-R0-HL3-ontology-terms
    a sh:NodeShape ;
    sh:targetClass rdfs:Class, rdf:Property, owl:ObjectProperty, owl:DatatypeProperty ;
    ont:hierarchyLevel 3 ;
    sh:property
        [
            sh:path rdfs:isDefinedBy ;
            sh:class owl:Ontology
        ] ,
        [
            sh:path ( rdfs:isDefinedBy [ sh:inversePath schema:hasPart ] ) ;
            sh:class schema:DataCatalog
        ] .
```

When defining shapes like these in prez, it is important to always fully specify the path to each hierarchical level (in this case, the items are level 3, the ontology is level 2, and the catalog is level 1).
If you only specify the path one level up, prez will error because it cannot find the correct node shapes for the entire route.

To avoid further errors, it is also useful to define any custom prefixes in `./config/prefixes.ttl`. If not specified, prez will attempt a best-effort guess at any unknown prefixes, which might lead to unexpected behaviour.
