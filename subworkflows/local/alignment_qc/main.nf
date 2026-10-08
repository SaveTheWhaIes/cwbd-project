// SUBWORKFLOW: ALIGNMENT_QC
// checks the library strandedness and where the reads fall on the genes with RSeQC
// both tools need the gene models as BED12, made from the GTF
// counts the reads per gene biotype with featureCounts for MultiQC

// import modules
include { EAUTILS_GTF2BED                                        } from '../../../modules/nf-core/ea-utils/gtf2bed/main'
include { RSEQC_INFEREXPERIMENT                                  } from '../../../modules/nf-core/rseqc/inferexperiment/main'
include { RSEQC_READDISTRIBUTION                                 } from '../../../modules/nf-core/rseqc/readdistribution/main'
include { SUBREAD_FEATURECOUNTS as SUBREAD_FEATURECOUNTS_BIOTYPE } from '../../../modules/nf-core/subread/featurecounts/main'
include { CUSTOM_MULTIQCCUSTOMBIOTYPE                            } from '../../../modules/nf-core/custom/multiqccustombiotype/main'

// reads the forward and reverse fractions from infer_experiment
// returns forward, reverse or unstranded with the thresholds of nf-core/rnaseq
def inferStrandedness(Path txt) {
    def fractions = txt.readLines()
        .findAll { line -> line.startsWith('Fraction of reads explained by') }
        .collect { line -> line.tokenize(':')[-1].trim() as double }
    def forward  = fractions[0]
    def reverse  = fractions[1]
    def assigned = forward + reverse
    if (assigned == 0) {
        return 'undetermined'
    }
    if (forward / assigned >= 0.8) {
        return 'forward'
    }
    if (reverse / assigned >= 0.8) {
        return 'reverse'
    }
    if (Math.abs(forward - reverse) / assigned < 0.1) {
        return 'unstranded'
    }
    return 'undetermined'
}

workflow ALIGNMENT_QC {

    take:
    ch_bam          // channel: [ val(meta), path(bam) ], coordinate sorted, duplicates marked
    ch_bai          // channel: [ val(meta), path(bai) ]
    gtf             // path: gene annotation GTF
    biotypes_header // path: MultiQC header for the biotype plot

    main:
    // converts the GTF into a BED12 file with one line per transcript
    EAUTILS_GTF2BED(channel.value([ [id: 'genes'], gtf ]))
    def ch_bed = EAUTILS_GTF2BED.out.bed.map { _meta, bed -> bed }

    // pairs every BAM with its index
    def ch_bam_bai = ch_bam.join(ch_bai)

    // fraction of reads that fit forward, reverse or unstranded
    RSEQC_INFEREXPERIMENT(ch_bam_bai, ch_bed)

    // warns when the samplesheet strandedness does not match the data
    RSEQC_INFEREXPERIMENT.out.txt
        .map { meta, txt -> [ meta, inferStrandedness(txt) ] }
        .filter { meta, inferred -> inferred != meta.strandedness }
        .subscribe { meta, inferred ->
            log.warn "Sample ${meta.id}: strandedness is '${meta.strandedness}' in the samplesheet, but RSeQC infer_experiment suggests '${inferred}'"
        }

    // reads on exons, introns and intergenic regions
    RSEQC_READDISTRIBUTION(ch_bam_bai, ch_bed)

    // reads per gene biotype (protein_coding, rRNA, misc_RNA, ...)
    SUBREAD_FEATURECOUNTS_BIOTYPE(
        ch_bam.map { meta, bam -> [ meta, bam, gtf ] }
    )

    // turns the biotype counts into a MultiQC bar plot and the rRNA share
    CUSTOM_MULTIQCCUSTOMBIOTYPE(
        SUBREAD_FEATURECOUNTS_BIOTYPE.out.counts,
        [ [:], biotypes_header ]
    )

    // MultiQC parses all reports, without the meta map
    def ch_multiqc_files = RSEQC_INFEREXPERIMENT.out.txt
        .mix(RSEQC_READDISTRIBUTION.out.txt)
        .mix(CUSTOM_MULTIQCCUSTOMBIOTYPE.out.tsv)
        .mix(CUSTOM_MULTIQCCUSTOMBIOTYPE.out.rrna)
        .map { _meta, txt -> txt }

    // emit the outputs
    emit:
    infer_experiment  = RSEQC_INFEREXPERIMENT.out.txt            // channel: [ val(meta), path(txt) ]
    read_distribution = RSEQC_READDISTRIBUTION.out.txt           // channel: [ val(meta), path(txt) ]
    biotype_counts    = SUBREAD_FEATURECOUNTS_BIOTYPE.out.counts // channel: [ val(meta), path(tsv) ]
    multiqc_files     = ch_multiqc_files                         // channel: [ path ]
}
