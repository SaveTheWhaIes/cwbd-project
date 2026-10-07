// SUBWORKFLOW: QUANTIFY
// expression per gene ans sample TPM
// first per sample with StringTie, then merge all samples into one table

// import modules
include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { MERGE_TPM           } from '../../../modules/local/merge_tpm/main'

workflow QUANTIFY {

    take:
    ch_bam // channel: [ val(meta), path(bam) ], coordinate sorted, duplicates marked
    gtf    // path: gene annotation GTF

    main:
    // quantifies the expression per gene and sample, using the BAM and GTF
    STRINGTIE_STRINGTIE(
        ch_bam.map { meta, bam -> [ meta, bam, [] ] },
        'expression-estimation',
        gtf
    )

    // merges the per sample expression into one table with TPM values
    MERGE_TPM(
        STRINGTIE_STRINGTIE.out.abundance
            .map { _meta, abundance -> abundance }
            .toSortedList { a, b -> a.name <=> b.name }
    )

    // emit the outputs
    emit:
    abundance = STRINGTIE_STRINGTIE.out.abundance // channel: [ val(meta), path(gene abundance) ]
    tpm       = MERGE_TPM.out.tpm                 // channel: path(gene_tpm.tsv)
}
