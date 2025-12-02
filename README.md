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

Install the kurra tool to create the dataset and upload data.
```
python -m pip install kurra
```

Once the server is up, datasets can be created, such as the test dataset in `./data/dataset-config.ttl`.

```
kurra db create http://localhost:3030 --config ../config/dataset-config.ttl
```

You'll see a warning in the docker logs of the `fuseki` service:

```
WARN  GeoAssembler    :: Dataset empty. Spatial Index not constructed. Server will require restarting after adding data and any updates to build Spatial Index.
```

We need some data to display.
Go to http://localhost:3030/#/dataset/fuseki-ogc/upload to upload some data.

Alternatively, we can use prezmanifest (`uv tool install prezmanifest`):
(the options specify to only update the DB, not the local files)

The following will add a catalogue of example vocabularies:
```
python ../config/upload_background.py
pm sync ../manifest.ttl http://localhost:3030/fuseki-ogc/ True False True False
```

Restart the fuseki and prez instances so the geospatial index gets built and the prez endpoints get loaded.

```
task rs
```

Upload the custom configuration for the prez instance:
```
kurra db upload ../config/prez-config.ttl http://localhost:3030/fuseki-ogc -g http://prez-system
```

Finally, restart prez again:
```
docker compose restart prez

```

Check the logs to see if the prez endpoint configuration was loaded correctly:

```
docker compose logs -f prez
```

If you see the following, the endpoints were loaded correctly:

```
prez-1  | 2025-12-02 15:45:11.212 [INFO] prez: Starting up
prez-1  | 2025-12-02 15:45:11.224 [INFO] prez.services.app_service: Checking SPARQL endpoint http://fuseki:3030/fuseki-ogc/query is online
prez-1  | 2025-12-02 15:45:11.246 [INFO] prez.services.app_service: Successfully connected to triplestore SPARQL endpoint
prez-1  | 2025-12-02 15:45:11.303 [INFO] prez.services.app_service: 14 prefixes bound from data repo
prez-1  | 2025-12-02 15:45:11.308 [INFO] prez.services.app_service: 8 prefixes bound from file standard.ttl
prez-1  | 2025-12-02 15:50:52.058 [INFO] prez.services.app_service: Generating prefixes for 12,854 IRIs.
prez-1  | 2025-12-02 15:50:52.229 [INFO] prez.services.app_service: Generated prefixes for 12,854 IRIs. Skipped 2 IRIs.
prez-1  | 2025-12-02 15:45:11.645 [INFO] prez.services.app_service: Skipped IRI http://rs.tdwg.org/dwc/terms/
prez-1  | 2025-12-02 15:45:11.645 [INFO] prez.services.app_service: Skipped IRI http://www.w3.org/ns/prov-o#
prez-1  | 2025-12-02 15:45:11.653 [INFO] prez.services.app_service: No remote template queries found
prez-1  | 2025-12-02 15:45:11.663 [INFO] prez.services.app_service: No remote Jena FTS shapes found
prez-1  | 2025-12-02 15:45:11.681 [INFO] prez.services.generate_profiles: Prez default profiles loaded
prez-1  | 2025-12-02 15:45:11.697 [INFO] prez.services.generate_profiles: Remote profile(s) found and added
prez-1  | 2025-12-02 15:45:11.745 [INFO] prez.services.app_service: Remote endpoint definitions found and added for type https://prez.dev/ont/DynamicEndpoint
prez-1  | 2025-12-02 15:45:11.760 [INFO] prez.services.app_service: No remote endpoint definitions found for type https://prez.dev/ont/OGCFeaturesEndpoint
prez-1  | 2025-12-02 15:45:11.772 [INFO] prez.services.app_service: Populated API info
prez-1  | 2025-12-02 15:45:11.780 [INFO] prez.services.app_service: No remote queryable definitions found
prez-1  | 2025-12-02 15:45:11.780 [INFO] prez.services.app_service: No local queryable definitions found
prez-1  | 2025-12-02 15:45:11.851 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}
prez-1  | 2025-12-02 15:45:11.864 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}/objects
prez-1  | 2025-12-02 15:45:11.869 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}
prez-1  | 2025-12-02 15:45:11.874 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}
prez-1  | 2025-12-02 15:45:11.886 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs
prez-1  | 2025-12-02 15:45:11.891 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items/{itemId}/objects/{objectId}
prez-1  | 2025-12-02 15:45:11.904 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections/{recordsCollectionId}/items
prez-1  | 2025-12-02 15:45:11.915 [INFO] prez.routers.custom_endpoints: Added dynamic route: /catalogs/{catalogId}/collections


```

If you don't see any dynamic routes added, upload the custom endpoint configuration again and restart:

```
kurra db upload ../config/prez-config.ttl http://localhost:3030/fuseki-ogc -g http://prez-system
task prez-rs
```

## Improving OntPub compliance

To properly work with the custom Prez endpoint definitions for ontologies, we recommend that ontologies conform to the [OntPub Profile](https://agldwg.github.io/ontpub-profile/specification.html). Specifically, Prez needs all classes and properties defined in an ontology to have a `rdfs:isDefinedBy` property linking back to the ontology resource itself, as well as a `skos:prefLabel` or `sdo:name` for proper display in prez-ui.

However, certain example ontologies in this catalogue such as ADMS do not conform to this profile out of the box. To mitigate this, you can simply run the `./ontpub-compliance.sh` script, which will add the necessary properties.

To improve other added ontologies, new SPARQL queries may be added to the `ontpub-compliance` directory, and the script will automatically pick them up. When adding new INSERT queries, make sure that they check for existence of the inserted triples, in order to not insert duplicate data when executing this script multiple times.

## Understanding the prez custom endpoint configuration

In `./config/prez-config.ttl`, you'll find custom definitions for the /items endpoints for ontologies.

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

## Understanding Prez profiles

In `./config/prez-config.ttl`, you'll also find a profile definition for ontologies, which will enable prez-ui to handle these objects better.

```
<https://prez.dev/profile/ontology-object>
    a prof:Profile, prez:ObjectProfile ;
    dcterms:identifier "ontology-object"^^xsd:token ;
    dcterms:description "An ontology." ;
    dcterms:title "Ontology profile" ;
    altr-ext:constrainsClass owl:Ontology ;
    altr-ext:hasDefaultResourceFormat "text/anot+turtle" ;
    altr-ext:hasResourceFormat
        "application/ld+json",
        "application/rdf+xml",
        "text/anot+turtle",
        "text/turtle" ;
    sh:property
    [
          sh:path
              [
                  sh:union (
                               [ shext:bNodeDepth "2" ]
                               shext:allPredicateValues
                               [
                                  sh:path [ sh:inversePath rdfs:isDefinedBy ] ;
                               ]
                               [
                                  sh:path ([ sh:inversePath rdfs:isDefinedBy ] rdf:type) ;
                               ]
                           )
              ]
      ] ;
.
```

The key here is in the `sh:property` path, which specifies the path to the `owl:Class` and `owl:ObjectProperty` resources that are linked to the ontology by the inverse relation `rdfs:isDefinedBy`. When properly set in the data (e.g., by executing the OntPub compliance script in this repository), this will allow Prez to list the classes and properties an ontology defines directly in the API response. Prez-lib (and/or prez-ui) can then properly process these relations to adjust the item display.
