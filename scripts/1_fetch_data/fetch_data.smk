configfile: "scripts/1_fetch_data/config.json"

rule all:
    input: "data/resources/organisms_data"

rule ncbi_query:
    output:
        "data/resources/ncbi_extraction"
    params:
        query = config['query']
    shell:
        "esearch -db assembly -query {params.query} | efetch -format docsum  | grep -v xml > {output}"
#       "esearch -db assembly -query {params.query} | efetch -format docsum   > {output}" ### ( grep is useless depending on esearch)        

rule frauder_le_xml:
    """
    The xml file structure is the following:
        <DocumentSummarySet> <-- root
            <DocumentSummary> <-- one for each organism
                first organism data
            </DocumentSummary>
            ...
            <DocumentSummary>
                last organism data
            </DocumentSummary>
        </DocumentSummarySet>
    When the number of results is high, data is divided in multiple trees (unknown cause), 
    so there are multiple roots in the xml file. Proper XML files have only one root,
    and the python xml library doesn't work with poorly constructed data.
    The xml_rewrite.py script creates a new xml file with only one root.
    """
    input:
        "data/resources/ncbi_extraction"
    output:
        "data/resources/rooted_extraction"
    shell:
        """
        python3 scripts/fetch_data/python/xml_rewrite.py {input} {output}\
        && rm {input}
        """

rule data_analysis:
    """
    Writing important data in a readable text file.
    """
    input:
        "data/resources/rooted_extraction"
    output:
        "data/resources/organisms_data"
    shell:
        "python3 scripts/fetch_data/python/xml_reader.py {input} {output}"