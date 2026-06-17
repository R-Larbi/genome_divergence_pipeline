def get_phylum_pairs(wildcards):
    cp_output_phylum = checkpoints.get_phylum_list.get(**wildcards).output[0]
    PHYLUM_PAIRS = []
    with open(cp_output_phylum, "r") as reader:
        for line in reader.readlines():
            PHYLUM_PAIRS.append(line.strip())
    return expand(pathResults + "seaview_alignment/Per_BUSCO_Alignment/{pair}/full_alignment.dNdS", pair=PHYLUM_PAIRS)

checkpoint get_phylum_list:
    input:
        tax_data = pathResources + "ncbi_dataset_eukaryota.taxonomy",
        species = pathResults + "Genus_Clustering/full_representative_species"
    output:
        fam = pathResults + "list_pairs_phylum",
        singles = pathResults + "list_singletons_phylum"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/generate_pairs.py -i {input.species} -t {input.tax_data} -l "Phylum" -o {output.fam} -s {output.singles}
        """

rule create_pair_list_phylum:
    input:
        pairs = pathResults + "list_pairs_phylum",
        busco = pathBUSCO + "busco_full.fa"
    output:
        touch(temp("pair_lists_phylum_done.flag"))
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -i {input.pairs} -b {input.busco} -o {pathResults}busco_pairs_phylum
        """

rule separate_by_pair_genus:
    """
    For this rule, we do not specify the inputs.
    If we did, then snakemake would check if the input was updated, and if it was, it would run the rule for EVERY pair.
    We want it to only run the rule for missing pairs, so we only specify the output so it only checks for missing pairs.
    """
    input:
        "pair_lists_phylum_done.flag"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/busco_pairs"
    shell:
        """
        mkdir -p {pathResults}seaview_alignment/Per_BUSCO_Alignments/{wildcards.pair}
        python3 {pathScripts}4_seaview_analysis/python/separate_by_pair.py -p {wildcards.pair} -b {pathResults}busco_pairs_phylum -o {output}
        """

rule seaview_genus:
    input:
        pair  = pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/busco_pairs",
        busco = pathBUSCO + "busco_full.fa",
        db    = pathBUSCO + "busco_full.fa.ndb"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/per_busco_alignment.dNdS"
    params:
        codes = get_gen_codes
    shell:
        """
        csh scripts/4_seaview_analysis/csh/Aln_dNdS_run_all.csh {input.pair} {input.busco} {wildcards.pair} {params.codes[0]} {params.codes[1]} {output}
        """

rule get_medians_genus:
    input:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/per_busco_alignment.dNdS"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/full_alignment.dNdS"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/median_dnds.py -i {input} -o {output}
        """

rule summarize_phylum:
    input:
        get_phylum_pairs
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        elt=' ' read -r -a array <<< "{input}"
        for align in ${{array[@]}};
        do
            if $(wc -l < "$align") -gt 1; then tail -n+2 "$align" >> {output}; fi
        done
        """

rule filter_phylum:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    output:
        pairs = pathResults + "phylum_close_species_pairs",
        full = pathResults + "phylum_list_processed_species"
    shell:
        """
        python3 {pathScripts}4_seaview_alignment/python/filter_clusters.py -i {input} -t 0.5 -o {output.pairs} -f {output.full}
        """

rule silixx_phylum:
    input:
        pairs = pathResults + "phylum_close_species_pairs",
        full = pathResults + "phylum_list_processed_species"
    output:
        pathResults + "phylum_clustered_species"
    shell:
        """
        silixx $(wc -l < {input.full}) {input.pairs} > {output}
        """

rule filter_clusters_phylum:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "phylum_clustered_species"
    output:
        pathResults + "filtered_phylum_clustered_species"
    shell:
        """
        python3 {pathScripts}3_cds_extraction/python/filter_clusters.py -i {input} -o {output}
        """

checkpoint matrix_cluster_phylum:
    """
    Generate a pseudo-distance matrix using dS for each cluster
    """
    input:
        clust = pathResults + "filtered_phylum_clustered_species",
        ds = pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    output:
        directory(pathResults + "Phylum_Clustering")
    shell:
        """
        mkdir -p {pathResults}Phylum_Clustering
        python3 {pathScripts}4_seaview_alignment/python/generate_matrix.py -i {input} -d {ds} -l "Phylum" -o {pathResults}Phylum_Clustering/
        """


"""
Make check for all clusters in genus for getting representatives, and then repeat for phylum
"""

def check_phylum_clusters(wildcards):
    cp_clusters_phylum = checkpoints.matrix_cluster_phylum.get(**wildcards).output[0]
    return expand(pathResults + "Phylum_Clustering/cluster_{clust}_matrix.txt", clust = glob_wildcards(os.path.join(cp_clusters_phylum, 'cluster_{clust}_matrix.txt')).clust)

rule final_step:
    input:
        check_phylum_clusters
    output:
        touch(temp("final_step.flag"))
    shell:
        """
        echo "Pipeline done"
        """

