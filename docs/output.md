# SaveTheWhaIes/cwbd-project: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [fastp](#fastp) - Adapter and quality trimming
- [HISAT2](#hisat2) - Alignment to the genome
- [picard MarkDuplicates](#picard-markduplicates) - Duplicate read marking
- [RSeQC](#rseqc) - Strandedness check and read distribution
- [Biotype counts](#biotype-counts) - Reads per gene biotype
- [StringTie](#stringtie) - Gene level quantification
- [TPM table](#tpm-table) - Gene TPM values of all samples in one table
- [featureCounts](#featurecounts) - Gene level read counts
- [Count table](#count-table) - Gene read counts of all samples in one table
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/). Samples sequenced in several runs (more than one samplesheet row with the same `sample`) are merged first, so there is one FastQC report per sample and read direction.

### fastp

<details markdown="1">
<summary>Output files</summary>

- `fastp/`
  - `*.fastp.html`: fastp report with read quality, adapter content and filtering statistics before and after trimming.
  - `*.fastp.json`: the same statistics in machine readable form, parsed by MultiQC.
  - `*.fastp.log`: fastp command line output.

</details>

[fastp](https://github.com/OpenGene/fastp) removes adapter sequences (detected automatically) and low quality bases from the reads. Bases below Phred 20 count as low quality, and reads shorter than 36 bp after trimming are discarded. The trimmed reads are not published by default; they are passed directly to the alignment step.

### HISAT2

<details markdown="1">
<summary>Output files</summary>

- `hisat2/log/`
  - `*.log`: HISAT2 alignment report containing the mapping results summary.

</details>

[HISAT2](http://daehwankimlab.github.io/hisat2/) is a fast and sensitive alignment program for mapping next-generation sequencing reads (both DNA and RNA) to a population of human genomes as well as to a single reference genome. It introduced a new indexing scheme called a Hierarchical Graph FM index (HGFM) which when combined with several alignment strategies, enable rapid and accurate alignment of sequencing reads. The aligned reads are coordinate sorted and indexed with [SAMtools](https://sourceforge.net/projects/samtools/files/samtools/) and passed on to duplicate marking; they are not published separately.

### picard MarkDuplicates

<details markdown="1">
<summary>Output files</summary>

- `picard/`
  - `<SAMPLE>.markdup.sorted.bam`: Coordinate sorted BAM file after duplicate marking. This is the final post-processed BAM file and so will be saved by default in the results directory.
  - `<SAMPLE>.markdup.sorted.bai`: BAI index file for coordinate sorted BAM file after duplicate marking.
  - `<SAMPLE>.markdup.sorted.metrics.txt`: Metrics file from MarkDuplicates.

</details>

Unless you are using [UMIs](https://emea.illumina.com/science/sequencing-method-explorer/kits-and-arrays/umi.html) it is not possible to establish whether the fragments you have sequenced from your sample were derived via true biological duplication (i.e. sequencing independent template fragments) or as a result of PCR biases introduced during the library preparation. The pipeline uses [picard MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates) to _mark_ the duplicate reads identified amongst the alignments to allow you to gauge the overall level of duplication in your samples. However, for RNA-seq data it is not recommended to physically remove duplicate reads from the alignments (unless you are using UMIs) because you expect a significant level of true biological duplication that arises from the same fragments being sequenced from for example highly expressed genes.

### StringTie

<details markdown="1">
<summary>Output files</summary>

- `stringtie/`
  - `*.coverage.gtf`: GTF file containing transcripts that are fully covered by reads.
  - `*.transcripts.gtf`: GTF file containing all of the annotated transcripts with their estimated abundances.
  - `*.gene.abundance.txt`: Text file containing gene abundances with coverage, FPKM and TPM values.
- `stringtie/<SAMPLE>.ballgown/`: Ballgown output directory.

</details>

[StringTie](https://ccb.jhu.edu/software/stringtie/) is run with `-e`, so it only estimates the abundance of the transcripts in the `--gtf` annotation and does not assemble new ones. The library strandedness from the samplesheet is passed on (`--rf` for `reverse`, `--fr` for `forward`).

### RSeQC

<details markdown="1">
<summary>Output files</summary>

- `rseqc/`
  - `*.infer_experiment.txt`: fraction of reads that fit a forward, reverse or unstranded library.
  - `*.read_distribution.txt`: number of reads on coding exons, UTRs, introns and the regions up and downstream of genes.

</details>

[RSeQC](https://rseqc.sourceforge.net/) checks the aligned reads against the gene models of the `--gtf`, converted to BED12 first. `infer_experiment.py` compares each read with the strand of the gene it overlaps. If 80 % or more of the assigned reads fit one direction the library is called `forward` or `reverse`, if both directions are within 10 % of each other it is `unstranded` (the thresholds of nf-core/rnaseq). When this differs from the samplesheet, the pipeline prints a warning but keeps running. `read_distribution.py` shows how many reads fall on exons versus introns and intergenic regions; a high intron share points to unspliced pre-mRNA or genomic DNA. Both reports are shown in the MultiQC report.

### Biotype counts

<details markdown="1">
<summary>Output files</summary>

- `featurecounts/biotype/`
  - `*.biotype.featureCounts.tsv`: reads per gene biotype for one sample.
  - `*.biotype_counts_mqc.tsv`: the same counts as a MultiQC bar plot.
  - `*.biotype_counts_rrna_mqc.tsv`: share of reads on rRNA genes, for the General Statistics table.

</details>

featureCounts counts the reads per `gene_biotype` of the `--gtf` (`-g gene_biotype`), the same way as the gene counts (exons, read pairs, strandedness from the samplesheet). The plot shows how much of a library is mRNA (`protein_coding`) and how much falls on non-coding RNA such as `rRNA`, `misc_RNA` (for example the 7SL RNAs Rn7s1 and Rn7s2) or `lncRNA`. The GTF needs the `gene_biotype` attribute, as Ensembl GTFs have; GENCODE GTFs call it `gene_type` and are not supported.

### TPM table

<details markdown="1">
<summary>Output files</summary>

- `tpm/`
  - `gene_tpm.tsv`: tab separated table with one row per gene and one column per sample, holding the gene TPM values from StringTie. The first two columns are `gene_id` and `gene_name`.

</details>

The gene abundance tables of all samples are merged into one table by `bin/merge_tpm.py`. If StringTie reports a gene on more than one row, the TPM values of these rows are summed. Columns are sorted by sample name and rows by gene ID.

### featureCounts

<details markdown="1">
<summary>Output files</summary>

- `featurecounts/`
  - `*.featureCounts.tsv`: read counts per gene for one sample, with the gene coordinates, length and name.
  - `*.featureCounts.tsv.summary`: number of read pairs that were assigned to a gene and why the others were not.

</details>

[featureCounts](https://subread.sourceforge.net/) counts the reads on the exons of each gene in the `--gtf` annotation (`-t exon -g gene_id`). For paired end data it counts fragments, not single reads (`--countReadPairs`). The library strandedness from the samplesheet is passed on (`-s 2` for `reverse`, `-s 1` for `forward`). Reads that map to several places or overlap more than one gene are not counted, and duplicates are counted. The summary is shown in the MultiQC report.

### Count table

<details markdown
<summary>Output files</summary>  
- `counts/`                                                        - `gene_counts.h one row per gene and one column per sample, holding the read counts from          featureCounts. Th_id` and`gene_name`.  
</details>  
The featureCounts tables of all samples are merged into one table by `bin/merrted by samplename and rows by gene ID. Unlike the TPM table, these raw counts can be used as inon tools likeDESeq2.

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://docs.seqera.io/platform-cloud/reports/overview) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
