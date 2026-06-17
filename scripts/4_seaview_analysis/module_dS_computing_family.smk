def get_family_pairs(wildcards):
    cp_output_family = checkpoints.get_family_list.get(**wildcards).output[0]
    FAMILY_PAIRS = []
    with open(cp_output_family, "r") as reader:
        for line in reader.readlines():
            FAMILY_PAIRS.append(line.strip())
    return expand(pathResults + "seaview_alignment/Per_BUSCO_Alignment/{pair}/full_alignment.dNdS", pair=FAMILY_PAIRS)

checkpoint get_family_list:
    input:
        tax_data = pathResources + "ncbi_dataset_eukaryota.taxonomy",
        species = pathResults + "Genus_Clustering/full_representative_species"
    output:
        fam = pathResults + "list_pairs_family",
        singles = pathResults + "list_singletons_family"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/generate_pairs.py -i {input.species} -t {input.tax_data} -l "Family" -o {output.fam} -s {output.singles}
        """

rule create_pair_list_family:
    input:
        pairs = pathResults + "list_pairs_family",
        busco = pathBUSCO + "busco_full.fa"
    output:
        touch(temp("pair_lists_family_done.flag"))
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -i {input.pairs} -b {input.busco} -o {pathResults}busco_pairs_family
        """

rule separate_by_pair_genus:
    """
    For this rule, we do not specify the inputs.
    If we did, then snakemake would check if the input was updated, and if it was, it would run the rule for EVERY pair.
    We want it to only run the rule for missing pairs, so we only specify the output so it only checks for missing pairs.
    """
    input:
        "pair_lists_family_done.flag"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/busco_pairs"
    shell:
        """
        mkdir -p {pathResults}seaview_alignment/Per_BUSCO_Alignments/{wildcards.pair}
        python3 {pathScripts}4_seaview_analysis/python/separate_by_pair.py -p {wildcards.pair} -b {pathResults}busco_pairs_family -o {output}
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

rule summarize_family:
    input:
        get_family_pairs
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/family_level_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        elt=' ' read -r -a array <<< "{input}"
        for align in ${{array[@]}};
        do
            if $(wc -l < "$align") -gt 1; then tail -n+2 "$align" >> {output}; fi
        done
        """

rule filter_family:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/family_level_full_alignment.dNdS"
    output:
        pairs = pathResults + "family_close_species_pairs",
        full = pathResults + "family_list_processed_species"
    shell:
        """
        python3 {pathScripts}4_seaview_alignment/python/filter_clusters.py -i {input} -t 0.2 -o {output.pairs} -f {output.full}
        """

rule silixx_family:
    input:
        pairs = pathResults + "family_close_species_pairs",
        full = pathResults + "family_list_processed_species"
    output:
        pathResults + "family_clustered_species"
    shell:
        """
        silixx $(wc -l < {input.full}) {input.pairs} > {output}
        """

rule filter_clusters_family:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "family_clustered_species"
    output:
        pathResults + "filtered_family_clustered_species"
    shell:
        """
        python3 {pathScripts}3_cds_extraction/python/filter_clusters.py -i {input} -o {output}
        """

checkpoint matrix_cluster_family:
    """
    Generate a pseudo-distance matrix using dS for each cluster
    """
    input:
        clust = pathResults + "filtered_family_clustered_species",
        ds = pathResults + "seaview_alignment/Alignment_Summaries/family_level_full_alignment.dNdS"
    output:
        directory(pathResults + "Family_Clustering")
    shell:
        """
        mkdir -p {pathResults}Family_Clustering
        python3 {pathScripts}4_seaview_alignment/python/generate_matrix.py -i {input} -d {ds} -l "Family" -o {pathResults}Family_Clustering/
        """


"""
Make check for all clusters in genus for getting representatives, and then repeat for family
"""

def check_family_clusters(wildcards):
    cp_clusters_family = checkpoints.matrix_cluster_family.get(**wildcards).output[0]
    return expand(pathResults + "Family_Clustering/cluster_{clust}_representative_species", clust = glob_wildcards(os.path.join(cp_clusters_family, 'cluster_{clust}_matrix.txt')).clust)


rule get_representatives_family:
    """
    Get representative for each cluster on family step
    """
    input:
        pathResults + "Family_Clustering/cluster_{clust}_matrix.txt"
    output:
        pathResults + "Family_Clustering/cluster_{clust}_representative_species"
    shell:
        """
        apptainer exec docker://gitlab-registry.in2p3.fr/lbbe/poleinfo/rockercustom:latest Rscript {pathScripts}2_analysis_pipeline/Rscript/get_representatives.R {input} {output}
        """

rule concatenate_rep_family:
    """
    Concatenate all representatives for family clusters alongside singletons
    """
    input:
        check_genus_clusters
    output:
        pathResults + "Family_Clustering/full_representative_species"
    shell:
        """
        cat {pathResults}Family_Clustering/cluster_*_representative_species {pathResults}list_singletons_family > {output}
        """

