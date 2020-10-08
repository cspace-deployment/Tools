# re-install all functions
./runpsql.sh pahma 5307 culture_hierarchy/CreateCultureHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 culture_hierarchy/PopulateCultureHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 culture_hierarchy/RefreshCultureHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 culture_hierarchy/UpdateCultureHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 material_hierarchy/CreateMaterialHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 material_hierarchy/PopulateMaterialHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 material_hierarchy/RefreshMaterialHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 material_hierarchy/UpdateMaterialHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 object_location/CreateCurrentLocationTable.sql nuxeo
./runpsql.sh pahma 5307 object_location/CreateCurrentLocationView.sql nuxeo
./runpsql.sh pahma 5307 object_location/CreateObjectPlaceLocationTable.sql nuxeo
./runpsql.sh pahma 5307 object_location/CreateObjectPlaceTable.sql nuxeo
./runpsql.sh pahma 5307 object_location/CreateObjectPlaceView.sql nuxeo
./runpsql.sh pahma 5307 object_location/RefreshObjectPlaceLocationTable.sql nuxeo
./runpsql.sh pahma 5307 object_location/UpdateObjectPlaceLocation.sql nuxeo
./runpsql.sh pahma 5307 place_hierarchy/CreatePlacenameHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 place_hierarchy/PopulatePlacenameHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 place_hierarchy/UpdatePlacenameHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 taxon_hierarchy/CreateTaxonHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 taxon_hierarchy/PopulateTaxonHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 taxon_hierarchy/RefreshTaxonHierarchyTable.sql nuxeo
./runpsql.sh pahma 5307 taxon_hierarchy/UpdateTaxonHierarchyTable.sql nuxeo
# it seems these 2 query have to run after the object_place_location queries
./runpsql.sh pahma 5307 material_hierarchy/AddMaterialtoOPL.sql nuxeo
./runpsql.sh pahma 5307 culture_hierarchy/object_culture_hierarchy_table.sql nuxeo
