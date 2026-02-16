import json

configfile: "scripts/1_fetch_data/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

part = str(config["partition"])

rule all:
    params:
        p = config["partition"]
    input:
        pathResources + part + "_organisms_data"

rule ncbi_query:
    output:
        pathResources + "ncbi_extraction"
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
        pathResources + "ncbi_extraction"
    output:
        pathResources + "rooted_extraction"
    shell:
        """
        python3 {pathScripts}1_fetch_data/python/xml_rewrite.py {input} {output}\
        && rm {input}
        """

rule data_analysis:
    """
    Writing important data in a readable text file.
    """
    input:
        pathResources + "rooted_extraction"
    output:
        pathResources + "organisms_data"
    shell:
        "python3 {pathScripts}1_fetch_data/python/xml_reader.py {input} {output}"

rule partitioning:
    """
    Only keeping nth tenth of the data.
    """
    input:
        pathResources + "organisms_data"
    output:
        pathResources + part + "_organisms_data"
    params:
        part = config["partition"]
    shell:
        """
        python3 {pathScripts}1_fetch_data/python/partition_organisms_data.py -i {input} -p {params.part} -o {output}
        """