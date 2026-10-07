// SUBWORKFLOW: QC_TRIM
// concatenates runs of the same sample, raw read QC and trimming, and then aligns the reads to the reference genome

// import modules
include { CAT_FASTQ } from '../../../modules/nf-core/cat/fastq/main'
include { FASTQC    } from '../../../modules/nf-core/fastqc/main'
include { FASTP     } from '../../../modules/nf-core/fastp/main'

workflow QC_TRIM {

    take:
    ch_reads // channel: [ val(meta), [ reads ] ], several runs of one sample already grouped

    main:
    // branch the reads channel into single-end and paired-end reads, then concatenate the paired-end reads
    def ch_runs = ch_reads.branch { meta, reads ->
        single:   reads.size() == (meta.single_end ? 1 : 2)
        multiple: true
    }
    
    // concatenate the paired-end reads if multiple true
    CAT_FASTQ(ch_runs.multiple)
    
    // merge the single-end reads with the concatenated paired-end reads
    def ch_merged = ch_runs.single.mix(CAT_FASTQ.out.reads)

    // QC the merged reads
    FASTQC(ch_merged)

    // fastp expects an adapter fasta as third tuple element; [] means none,
    // fastp then auto-detects adapters
    FASTP(
        ch_merged.map { meta, reads -> [ meta, reads, [] ] },
        false, // discard_trimmed_pass: keep the trimmed reads
        false, // save_trimmed_fail
        false  // save_merged
    )

    // MultiQC only needs the report files, not the meta map
    def ch_multiqc_files = FASTQC.out.zip.map { _meta, zip -> zip }
        .mix(FASTP.out.json.map { _meta, json -> json })

    // reads are the trimmed reads, the input for ALIGN
    emit:
    reads         = FASTP.out.reads   // channel: [ val(meta), [ trimmed reads ] ]
    multiqc_files = ch_multiqc_files  // channel: [ path ]
}
