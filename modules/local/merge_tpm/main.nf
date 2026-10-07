process MERGE_TPM {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/1841daa69f98a0b0ffcb8f545070c8350a75febb167202136eab0990131d31c0/data' :
        'community.wave.seqera.io/library/python:3.14.5--dc8358b3c5eeb927' }"

    input:
    path abundances // StringTie gene abundance tables, one per sample

    output:
    path "gene_tpm.tsv", emit: tpm
    tuple val("${task.process}"), val('python'), eval("python3 --version | sed 's/Python //'"), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    merge_tpm.py --output gene_tpm.tsv ${abundances}
    """

    stub:
    """
    touch gene_tpm.tsv
    """
}
