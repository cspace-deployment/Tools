# drop and then recreate all UCB Solr cores based on the content of this script
# and the default configuration available in solr default configsets

# this script inspired by https://github.com/Brown-University-Library/bul-traject/blob/master/solr7/define_schema.sh
# thanks!

SOLR_PORT="8983"

# for solr8 as deployed on my laptop
# SOLR_CMD=~/solr8/bin/solr

# for solr8 as deployed on RTL-managed Ubuntu servers
SOLR_CMD=/opt/solr/bin/solr

SOLR_CORES="bampfa-public
bampfa-internal
botgarden-public
botgarden-internal
botgarden-propagations
cinefiles-public
pahma-public
pahma-internal
pahma-locations
pahma-osteology
ucjeps-public
ucjeps-media
"

function define_field_types()
{
    # ====================
    # Field types
    # ====================
    echo "Defining new types, redefining others..."

    echo "  alphaOnlySort..."
    curl -S -X POST -H 'Content-type:application/json' --data-binary '{
      "add-field-type" : {
         "name":"alphaOnlySort",
         "class":"solr.TextField",
         "sortMissingLast":"true",
         "omitNorms":"true",
         "analyzer" : {
            "tokenizer":{"class":"solr.KeywordTokenizerFactory"},
            "filters":[
              {
                "class":"solr.LowerCaseFilterFactory"
              },
              {
                "class":"solr.TrimFilterFactory"
              },
              {
                "class":"solr.PatternReplaceFilterFactory",
                "pattern":"([^a-z])",
                "replacement":"",
                "replace":"all"
              }
          ]
        }
      }
    }' $SOLR_CORE_URL/schema

    # Notice that the core must be reloaded for this field (that has a default value)
    # to be registered and become effective. See note at the bottom of this script.

    #return 0
    echo "  text_general..."
    curl -S -X POST -H 'Content-type:application/json' --data-binary '{
        "replace-field-type": {
            "name": "text_general",
            "class": "solr.TextField",
            "multiValued":true,
            "positionIncrementGap": "100",
            "indexAnalyzer": {
                "tokenizer": {
                    "class": "solr.ClassicTokenizerFactory"},
                "filters": [{
                    "class": "solr.StopFilterFactory",
                    "words": "lang/stopwords_en.txt",
                    "ignoreCase": "true"},
                    {
                        "class": "solr.ASCIIFoldingFilterFactory"},
                    {
                        "class": "solr.LowerCaseFilterFactory"},
                    {
                        "class": "solr.EnglishPossessiveFilterFactory"},
                    {
                        "class": "solr.EnglishMinimalStemFilterFactory"}]},
            "queryAnalyzer": {
                "tokenizer": {
                    "class": "solr.ClassicTokenizerFactory"},
                "filters": [{
                    "class": "solr.SynonymFilterFactory",
                    "expand": "true",
                    "synonyms": "synonyms.txt",
                    "ignoreCase": "true"},
                    {
                        "class": "solr.StopFilterFactory",
                        "words": "lang/stopwords_en.txt",
                        "ignoreCase": "true"},
                    {
                        "class": "solr.ASCIIFoldingFilterFactory"},
                    {
                        "class": "solr.LowerCaseFilterFactory"},
                    {
                        "class": "solr.EnglishPossessiveFilterFactory"},
                    {
                        "class": "solr.EnglishMinimalStemFilterFactory"}]},
        }
    }' $SOLR_CORE_URL/schema
}

function define_fields()
    {
    # ====================
    # Fields
    #
    # ====================
    echo "Defining field text..."

    # Notice that we map "text" to "text_en" rather than to "text_general"
    # because Solr 4's "text" field behaved like "text_en" due to the
    # use of the SnowballFilter.
    curl -S -X POST -H 'Content-type:application/json' --data-binary '{
      "add-field":{
        "name":"text",
        "type":"text_general",
        "multiValued":true,
        "stored":false,
        "indexed":true
      }
    }' $SOLR_CORE_URL/schema
}

function copy_fields()
{
    # ====================
    # Copy fields
    # ====================

    curl -S -X POST -H 'Content-type:application/json' --data-binary "{
      \"add-copy-field\":{
        \"source\": \"$1\",
        \"dest\": [ \"$2\" ]}
    }" $SOLR_CORE_URL/schema
}

function create_copy_fields()
    {
    echo "Reading field definition for copyFields from $1"
    while read field_name
    do
      txt_field_name=${field_name/_*/_txt}
      echo "Making copyFields for $field_name $txt_field_name ..."
      copy_fields $field_name $txt_field_name
    done < $1
    }

function define_dynamic_fields()
{
    # right now this is a NOOP:
    # we only use the standard, pre-defined dynamic fields
    return 0
    # ====================
    # Dynamic fields
    # ====================
    echo "Defining dynamic fields..."
    curl -S -X POST -H 'Content-type:application/json' --data-binary '{
      "add-dynamic-field":{
        "name":"*_txt",
        "type":"text_general",
        "multiValued":true,
        "indexed":true,
        "stored":true},
    }' $SOLR_CORE_URL/schema
}

function define_special_fields()
{
    # ====================
    # special fields
    # ====================
    echo "Defining special fields for $1..."

    if [[ "$1" = "pahma-public" || "$1" == "pahma-internal" ]]; then
        curl -S -X POST -H 'Content-type:application/json' --data-binary '{
            "add-field":{
                "name":"objname_sort",
                "type":"alphaOnlySort",
                "stored":false,
                "indexed":true}
        }' $SOLR_CORE_URL/schema
        curl -S -X POST -H 'Content-type:application/json' --data-binary '{
            "add-copy-field":{"source":
                "objname_s",
                "dest": [ "objname_sort" ]}
        }' $SOLR_CORE_URL/schema
        curl -S -X POST -H 'Content-type:application/json' --data-binary '{
            "add-copy-field":{"source":
                "objmusno_s",
                "dest": [ "objmusno_s_lower" ]}
        }' $SOLR_CORE_URL/schema
    fi
}

for SOLR_CORE in $SOLR_CORES
do
    SOLR_CORE_URL="http://localhost:$SOLR_PORT/solr/$SOLR_CORE"
    # ====================
    # Recreate the Solr core and update the solrconfig.xml file
    # ====================
    echo "Recreating core: $SOLR_CORE_URL ..."
    $SOLR_CMD delete -c $SOLR_CORE
    $SOLR_CMD create -c $SOLR_CORE

    echo "Updating config files..."
    echo "$SOLR_RELOAD_URL"

    # Our custom solrconfig to mimic Solr 4 behavior that Blacklight needs
    #cp ./solr7/solrconfig7.xml $SOLR_CONFIG_XML

    # Use english stop words for text_general fields (to behave like our Solr 4 instance did)
    #cp $STOPWORDS_EN_FILE $STOPWORDS_FILE
    SOLR_RELOAD_URL="http://localhost:$SOLR_PORT/solr/admin/cores?action=RELOAD&core=$SOLR_CORE"
    echo "Loading new config..."
    define_field_types
    define_fields
    define_dynamic_fields
    define_special_fields ${SOLR_CORE}
    create_copy_fields ${SOLR_CORE}.fields.txt

    # add all these to the 'catch-all' field
    copy_fields '*_s'   'text'
    copy_fields '*_ss'  'text'
    copy_fields '*_txt' 'text'

    echo "Reloading core ${SOLR_CORE}..."
    curl -S "$SOLR_RELOAD_URL"
done

# ====================
# Use this to export all the *actual* fields defined in the code
# *after* importing data
#
# curl -S $SOLR_CORE_URL/admin/luke?numTerms=0 > luke7.xml
# ====================
