/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { QC_TRIM                } from '../subworkflows/local/qc_trim/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { ALIGN                  } from '../subworkflows/local/align/main'
include { MARKDUP                } from '../subworkflows/local/markdup/main'
include { QUANTIFY               } from '../subworkflows/local/quantify/main'
include { UNTAR                  } from '../modules/nf-core/untar/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_cwbdproject_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CWBDPROJECT {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()
    //
    // SUBWORKFLOW: Read QC and adapter/quality trimming
    //
    QC_TRIM(ch_samplesheet)
    ch_multiqc_files = ch_multiqc_files.mix(QC_TRIM.out.multiqc_files)

    //
    // SUBWORKFLOW: Align trimmed reads with HISAT2, sort and index
    //
    def ch_hisat2_index = []
    if (params.hisat2_index) {
        def hisat2_index = file(params.hisat2_index, checkIfExists: true)
        if (hisat2_index.name.endsWith('.tar.gz')) { // index can be folder or tar.gz
            UNTAR(channel.value([ [id: 'genome'], hisat2_index ]))
            ch_hisat2_index = UNTAR.out.untar
        } else {
            ch_hisat2_index = channel.value([ [id: 'genome'], hisat2_index ])
        }
    }

    ALIGN(
        QC_TRIM.out.reads,
        file(params.fasta, checkIfExists: true),
        file(params.gtf, checkIfExists: true),
        ch_hisat2_index
    )
    ch_multiqc_files = ch_multiqc_files.mix(ALIGN.out.multiqc_files)

    //
    // SUBWORKFLOW: Mark PCR/optical duplicates (flagged, not removed)
    //
    MARKDUP(ALIGN.out.bam)
    ch_multiqc_files = ch_multiqc_files.mix(MARKDUP.out.multiqc_files)

    //
    // SUBWORKFLOW: Gene level TPM per sample with StringTie and read counts with featureCounts, each merged into one table
    //
    QUANTIFY(
        MARKDUP.out.bam,
        file(params.gtf, checkIfExists: true)
    )
    ch_multiqc_files = ch_multiqc_files.mix(QUANTIFY.out.multiqc_files)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'cwbdproject_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'cwbdproject'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
