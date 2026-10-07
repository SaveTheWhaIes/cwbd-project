// SUBWORKFLOW: MARKDUP
// marks PCR and optical duplicates with Picard but doesn't remove them

// import modules
include { PICARD_MARKDUPLICATES } from '../../../modules/nf-core/picard/markduplicates/main'

workflow MARKDUP {

    take:
    ch_bam // channel: [ val(meta), path(bam) ], coordinate sorted

    main:
    // marks duplicates in the BAM file, creating a new BAM and index
    // fasta/fai tuple stays empty
    PICARD_MARKDUPLICATES(ch_bam, [ [:], [], [] ])

    // MultiQC parses the duplication metrics, without the meta map
    def ch_multiqc_files = PICARD_MARKDUPLICATES.out.metrics.map { _meta, metrics -> metrics }

    // emit the outputs
    emit:
    bam           = PICARD_MARKDUPLICATES.out.bam  // channel: [ val(meta), path(bam) ], duplicates flagged
    bai           = PICARD_MARKDUPLICATES.out.bai  // channel: [ val(meta), path(bai) ]
    multiqc_files = ch_multiqc_files               // channel: [ path ]
}
