// SUBWORKFLOW: ALIGN
// splice-aware alignment with HISAT2 against a reference genome, then sorting 
// either uses a pre-built HISAT2 index or builds one from the provided genome FASTA and GTF


// import modules
include { HISAT2_EXTRACTSPLICESITES } from '../../../modules/nf-core/hisat2/extractsplicesites/main'
include { HISAT2_BUILD              } from '../../../modules/nf-core/hisat2/build/main'
include { HISAT2_ALIGN              } from '../../../modules/nf-core/hisat2/align/main'
include { SAMTOOLS_SORT             } from '../../../modules/nf-core/samtools/sort/main'

workflow ALIGN {

    take:
    ch_reads     // channel: [ val(meta), [ reads ] ], trimmed
    fasta        // path: genome FASTA
    gtf          // path: gene annotation GTF
    hisat2_index // channel: [ val(meta), path(index) ], or [] to build one

    main:

    // reads the intron positions from the GTF
    HISAT2_EXTRACTSPLICESITES(channel.value([ [id: 'genome'], gtf ]))
    def ch_splicesites = HISAT2_EXTRACTSPLICESITES.out.txt

    // builds the HISAT2 index if not provided, otherwise use the provided one
    def ch_index = channel.empty()
    if (hisat2_index) {
        ch_index = hisat2_index
    } else {
        HISAT2_BUILD(
            ch_splicesites.map { meta, splicesites -> [ meta, fasta, gtf, splicesites ] },
            '200.GB' // splice aware index only with this much memory (nf-core/rnaseq default)
        )
        ch_index = HISAT2_BUILD.out.index
    }

    // aligns the reads to the reference genome, using the index and splice sites
    HISAT2_ALIGN(
        ch_reads,
        ch_index,
        ch_splicesites,
        false // save_unaligned
    )

    // sorts the aligned reads by coordinate and creates a BAM index
    SAMTOOLS_SORT(HISAT2_ALIGN.out.bam, [ [:], [], [] ], 'bai')

    // MultiQC only needs the report files, not the meta map
    def ch_multiqc_files = HISAT2_ALIGN.out.summary.map { _meta, log -> log }

    // emit the outputs
    emit:
    bam           = SAMTOOLS_SORT.out.bam    // channel: [ val(meta), path(bam) ], coordinate sorted
    bai           = SAMTOOLS_SORT.out.index  // channel: [ val(meta), path(bai) ]
    multiqc_files = ch_multiqc_files         // channel: [ path ]
}
