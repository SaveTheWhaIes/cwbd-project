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
    // Splice sites from the GTF, used for the index build and again during alignment.
    // Value channels throughout, so every sample reuses the same reference files
    HISAT2_EXTRACTSPLICESITES(channel.value([ [id: 'genome'], gtf ]))
    def ch_splicesites = HISAT2_EXTRACTSPLICESITES.out.txt

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

    HISAT2_ALIGN(
        ch_reads,
        ch_index,
        ch_splicesites,
        false // save_unaligned
    )

    // Coordinate sort; 'bai' makes samtools write the index in the same step
    SAMTOOLS_SORT(HISAT2_ALIGN.out.bam, [ [:], [], [] ], 'bai')

    def ch_multiqc_files = HISAT2_ALIGN.out.summary.map { _meta, log -> log }

    emit:
    bam           = SAMTOOLS_SORT.out.bam    // channel: [ val(meta), path(bam) ], coordinate sorted
    bai           = SAMTOOLS_SORT.out.index  // channel: [ val(meta), path(bai) ]
    multiqc_files = ch_multiqc_files         // channel: [ path ]
}
