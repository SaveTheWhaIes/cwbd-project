// SUBWORKFLOW: MARKDUP
// marks PCR and optical duplicates with Picard but doesn't remove them
// then collects alignment statistics of the marked BAM with SAMtools

// import modules and subworkflows
include { PICARD_MARKDUPLICATES } from '../../../modules/nf-core/picard/markduplicates/main'
include { BAM_STATS_SAMTOOLS    } from '../../nf-core/bam_stats_samtools/main'

workflow MARKDUP {

    take:
    ch_bam // channel: [ val(meta), path(bam) ], coordinate sorted

    main:
    // marks duplicates in the BAM file, creating a new BAM and index
    // fasta/fai tuple stays empty
    PICARD_MARKDUPLICATES(ch_bam, [ [:], [], [] ])

    // samtools stats, flagstat and idxstats on the marked BAM and its index
    // without a reference, samtools stats takes the mismatches from the NM and MD tags
    BAM_STATS_SAMTOOLS(
        PICARD_MARKDUPLICATES.out.bam.join(PICARD_MARKDUPLICATES.out.bai),
        [ [:], [], [] ]
    )

    // MultiQC parses the duplication metrics and the SAMtools reports, without the meta map
    def ch_multiqc_files = PICARD_MARKDUPLICATES.out.metrics
        .mix(BAM_STATS_SAMTOOLS.out.stats)
        .mix(BAM_STATS_SAMTOOLS.out.flagstat)
        .mix(BAM_STATS_SAMTOOLS.out.idxstats)
        .map { _meta, report -> report }

    // emit the outputs
    emit:
    bam           = PICARD_MARKDUPLICATES.out.bam    // channel: [ val(meta), path(bam) ], duplicates flagged
    bai           = PICARD_MARKDUPLICATES.out.bai    // channel: [ val(meta), path(bai) ]
    stats         = BAM_STATS_SAMTOOLS.out.stats     // channel: [ val(meta), path(stats) ]
    flagstat      = BAM_STATS_SAMTOOLS.out.flagstat  // channel: [ val(meta), path(flagstat) ]
    idxstats      = BAM_STATS_SAMTOOLS.out.idxstats  // channel: [ val(meta), path(idxstats) ]
    multiqc_files = ch_multiqc_files                 // channel: [ path ]
}
