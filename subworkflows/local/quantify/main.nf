include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { MERGE_TPM           } from '../../../modules/local/merge_tpm/main'

workflow QUANTIFY {

    take:
    ch_bam // channel: [ val(meta), path(bam) ], coordinate sorted, duplicates marked
    gtf    // path: gene annotation GTF

    main:
    // -e: only estimate the abundance of annotated transcripts, no novel assembly.
    // The module also takes a long read BAM, which we do not have: []
    STRINGTIE_STRINGTIE(
        ch_bam.map { meta, bam -> [ meta, bam, [] ] },
        'expression-estimation',
        gtf
    )

    // One table for all samples: wait for every sample, sorted by file name
    // so the column order is the same in every run
    MERGE_TPM(
        STRINGTIE_STRINGTIE.out.abundance
            .map { _meta, abundance -> abundance }
            .toSortedList { a, b -> a.name <=> b.name }
    )

    emit:
    abundance = STRINGTIE_STRINGTIE.out.abundance // channel: [ val(meta), path(gene abundance) ]
    tpm       = MERGE_TPM.out.tpm                 // channel: path(gene_tpm.tsv)
}