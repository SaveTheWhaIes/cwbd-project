include { PICARD_MARKDUPLICATES } from '../../../modules/nf-core/picard/markduplicates/main'

workflow MARKDUP {

    take:
    ch_bam // channel: [ val(meta), path(bam) ], coordinate sorted

    main:
    // Picard only needs a reference for CRAM input, so for BAM the
    // fasta/fai tuple stays empty
    PICARD_MARKDUPLICATES(ch_bam, [ [:], [], [] ])

    // MultiQC parses the duplication metrics, without the meta map
    def ch_multiqc_files = PICARD_MARKDUPLICATES.out.metrics.map { _meta, metrics -> metrics }

    emit:
    bam           = PICARD_MARKDUPLICATES.out.bam  // channel: [ val(meta), path(bam) ], duplicates flagged
    bai           = PICARD_MARKDUPLICATES.out.bai  // channel: [ val(meta), path(bai) ]
    multiqc_files = ch_multiqc_files               // channel: [ path ]
}
