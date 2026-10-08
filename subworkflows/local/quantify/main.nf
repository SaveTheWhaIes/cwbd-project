// SUBWORKFLOW: QUANTIFY
// expression per gene ans sample TPM
// first per sample with StringTie, then merge all samples into one table
// read counts per gene and sample with featureCounts, merged the same way

// import modules
include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { MERGE_TPM           } from '../../../modules/local/merge_tpm/main'
include { SUBREAD_FEATURECOUNTS } from '../../../modules/nf-core/subread/featurecounts/main'
include { MERGE_COUNTS        } from '../../../modules/local/merge_counts/main'

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

    // counts the read pairs per gene and sample, using the BAM and GTF
    SUBREAD_FEATURECOUNTS(
        ch_bam.map { meta, bam -> [ meta, bam, gtf ] }
    )

    // merges the per sample counts into one table
    MERGE_COUNTS(
        SUBREAD_FEATURECOUNTS.out.counts
            .map { _meta, counts -> counts }
            .toSortedList { a, b -> a.name <=> b.name }
    )

    // MultiQC parses the featureCounts summary, without the meta map
    def ch_multiqc_files = SUBREAD_FEATURECOUNTS.out.summary.map { _meta, summary -> summary }

    // emit the outputs
    emit:
    abundance = STRINGTIE_STRINGTIE.out.abundance // channel: [ val(meta), path(gene abundance) ]
    tpm       = MERGE_TPM.out.tpm                 // channel: path(gene_tpm.tsv)
    counts        = MERGE_COUNTS.out.counts           // channel: path(gene_counts.tsv)
    multiqc_files = ch_multiqc_files                  // channel: [ path ]
}
