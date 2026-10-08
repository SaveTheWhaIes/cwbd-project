// MODULE: MERGE_COUNTS
// merges the per sample read counts into one table

process MERGE_COUNTS {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/1841daa69f98a0b0ffcb8f545070c8350a75febb167202136eab0990131d31c0/data' :
        'community.wave.seqera.io/library/python:3.14.5--dc8358b3c5eeb927' }"

    input:
    path counts // featureCounts tables, one per sample

    output:
    path "gene_counts.tsv", emit: counts
    tuple val("${task.process}"), val('python'), eval("python3 --version | sed 's/Python //'"), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    // merge_counts.py lies in bin/
    // nextflow pry task
    script:
    """
    merge_counts.py --output gene_counts.tsv ${counts}
    """

    // creates annel logic quickly
    stub:
    """
    touch gene_counts.tsv
    """
}
