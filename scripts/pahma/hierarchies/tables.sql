select 'acquisitions_common',count(*) from acquisitions_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'batch_common',count(*) from batch_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'blobs_common',count(*) from blobs_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationauthorities_common',count(*) from citationauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citations_common',count(*) from citations_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claims_common',count(*) from claims_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'collectionobjects_common',count(*) from collectionobjects_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'conceptauthorities_common',count(*) from conceptauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'concepts_common',count(*) from concepts_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'conditionchecks_common',count(*) from conditionchecks_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'contacts_common',count(*) from contacts_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dimensions_common',count(*) from dimensions_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitions_common',count(*) from exhibitions_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'groups_common',count(*) from groups_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'imports_common',count(*) from imports_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'intakes_common',count(*) from intakes_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'loansin_common',count(*) from loansin_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'loansout_common',count(*) from loansout_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'locationauthorities_common',count(*) from locationauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'locations_common',count(*) from locations_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'media_common',count(*) from media_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'movements_common',count(*) from movements_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'notes_common',count(*) from notes_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectexit_common',count(*) from objectexit_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'organizations_common',count(*) from organizations_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'orgauthorities_common',count(*) from orgauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'personauthorities_common',count(*) from personauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'persons_common',count(*) from persons_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placeauthorities_common',count(*) from placeauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'places_common',count(*) from places_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'publicitems_common',count(*) from publicitems_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'relations_common',count(*) from relations_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'reports_common',count(*) from reports_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxon_common',count(*) from taxon_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxonomyauthority_common',count(*) from taxonomyauthority_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'valuationcontrols_common',count(*) from valuationcontrols_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'vocabularies_common',count(*) from vocabularies_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'vocabularyitems_common',count(*) from vocabularyitems_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'workauthorities_common',count(*) from workauthorities_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'works_common',count(*) from works_common c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'accessionusegroup',count(*) from accessionusegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'accessrestrictiongroup',count(*) from accessrestrictiongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'additionalsourcegroup',count(*) from additionalsourcegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'addressgroup',count(*) from addressgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'affiliatedpersonorggroup',count(*) from affiliatedpersonorggroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'ageestimategroup',count(*) from ageestimategroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'annotationgroup',count(*) from annotationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'anthropologyplaceownergroup',count(*) from anthropologyplaceownergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocactivitygroup',count(*) from assocactivitygroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocconceptgroup',count(*) from assocconceptgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocculturalcontextgroup',count(*) from assocculturalcontextgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocdategroup',count(*) from assocdategroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'associatedtaxagroup',count(*) from associatedtaxagroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocobjectgroup',count(*) from assocobjectgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocorganizationgroup',count(*) from assocorganizationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocpeoplegroup',count(*) from assocpeoplegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocpersongroup',count(*) from assocpersongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'assocplacegroup',count(*) from assocplacegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationagentinfogroup',count(*) from citationagentinfogroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationgroup',count(*) from citationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationpublicationinfogroup',count(*) from citationpublicationinfogroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationrelatedtermsgroup',count(*) from citationrelatedtermsgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationresourceidentgroup',count(*) from citationresourceidentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'citationtermgroup',count(*) from citationtermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimaltnamegroup',count(*) from claimaltnamegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimclaimantgroup',count(*) from claimclaimantgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimdocumentsarchivedgroup',count(*) from claimdocumentsarchivedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimgroupinvolvedgroup',count(*) from claimgroupinvolvedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claiminventoryinvolvedgroup',count(*) from claiminventoryinvolvedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimperiodinvolvedgroup',count(*) from claimperiodinvolvedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimreceivedgroup',count(*) from claimreceivedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'claimsiteinvolvedgroup',count(*) from claimsiteinvolvedgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'commonnamegroup',count(*) from commonnamegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'completenessgroup',count(*) from completenessgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'concepttermgroup',count(*) from concepttermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'conditioncheckgroup',count(*) from conditioncheckgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'conditiongroup',count(*) from conditiongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'contenteventnamegroup',count(*) from contenteventnamegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'contentobjectgroup',count(*) from contentobjectgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'contentothergroup',count(*) from contentothergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'creatorgroup',count(*) from creatorgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'currentlocationgroup',count(*) from currentlocationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dategroup',count(*) from dategroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dateofinitialresponsegroup',count(*) from dateofinitialresponsegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dateofnationalnagpraapprovalgroup',count(*) from dateofnationalnagpraapprovalgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dateofthirtydaynoticegroup',count(*) from dateofthirtydaynoticegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'dimensionsubgroup',count(*) from dimensionsubgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'emailgroup',count(*) from emailgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'envconditionnotegroup',count(*) from envconditionnotegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitionobjectgroup',count(*) from exhibitionobjectgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitionpersongroup',count(*) from exhibitionpersongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitionreferencegroup',count(*) from exhibitionreferencegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitionsectiongroup',count(*) from exhibitionsectiongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'exhibitionstatusgroup',count(*) from exhibitionstatusgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'faxnumbergroup',count(*) from faxnumbergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'galleryrotationgroup',count(*) from galleryrotationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'hazardgroup',count(*) from hazardgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'hybridparentgroup',count(*) from hybridparentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'legalreqsheldgroup',count(*) from legalreqsheldgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'lendergroup',count(*) from lendergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'loanstatusgroup',count(*) from loanstatusgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'localitygroup',count(*) from localitygroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'localnamegroup',count(*) from localnamegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'loctermgroup',count(*) from loctermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'materialgroup',count(*) from materialgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'measuredpartgroup',count(*) from measuredpartgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'nagpraclaimgroup',count(*) from nagpraclaimgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'nontextualinscriptiongroup',count(*) from nontextualinscriptiongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectcomponentgroup',count(*) from objectcomponentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectnamegroup',count(*) from objectnamegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectproductionorganizationgroup',count(*) from objectproductionorganizationgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectproductionpeoplegroup',count(*) from objectproductionpeoplegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectproductionpersongroup',count(*) from objectproductionpersongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'objectproductionplacegroup',count(*) from objectproductionplacegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'orgtermgroup',count(*) from orgtermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'ownershiphistorygroup',count(*) from ownershiphistorygroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'pahmaaltnumgroup',count(*) from pahmaaltnumgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'persontermgroup',count(*) from persontermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placeassocgroup',count(*) from placeassocgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placegeorefgroup',count(*) from placegeorefgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placenotegroup',count(*) from placenotegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placeownergroup',count(*) from placeownergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placereferencegroup',count(*) from placereferencegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'placetermgroup',count(*) from placetermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'publishergroup',count(*) from publishergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'recommendationoflocalcommitteegroup',count(*) from recommendationoflocalcommitteegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'recommendationofoversightcommitteegroup',count(*) from recommendationofoversightcommitteegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'referencegroup',count(*) from referencegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'repatriationclaimgroup',count(*) from repatriationclaimgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'responsefromnationalnagpragroup',count(*) from responsefromnationalnagpragroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'salvageprioritycodegroup',count(*) from salvageprioritycodegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'senttolocalcommitteegroup',count(*) from senttolocalcommitteegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'senttonationalnagpragroup',count(*) from senttonationalnagpragroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'senttooversightcommitteegroup',count(*) from senttooversightcommitteegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'structureddategroup',count(*) from structureddategroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxonauthorgroup',count(*) from taxonauthorgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxonomicidentgroup',count(*) from taxonomicidentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxonomicidenthybridparentgroup',count(*) from taxonomicidenthybridparentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'taxontermgroup',count(*) from taxontermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'techassessmentgroup',count(*) from techassessmentgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'technicalattributegroup',count(*) from technicalattributegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'techniquegroup',count(*) from techniquegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'telephonenumbergroup',count(*) from telephonenumbergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'textualinscriptiongroup',count(*) from textualinscriptiongroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'titlegroup',count(*) from titlegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'titletranslationsubgroup',count(*) from titletranslationsubgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'transfergroup',count(*) from transfergroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'typespecimengroup',count(*) from typespecimengroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'usagegroup',count(*) from usagegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'venuegroup',count(*) from venuegroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'webaddressgroup',count(*) from webaddressgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'workinggroup',count(*) from workinggroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');
select 'worktermgroup',count(*) from worktermgroup c join misc m on (c.id = m.id and m.lifecyclestate <> 'deleted');