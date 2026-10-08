# SaveTheWhaIes/cwbd-project: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

The pipeline takes short read RNA-seq data (single or paired end) and returns a table with the TPM and onw with the read counts of every annotated gene in every sample, together with QC reports for each step. To run it you need three things:

1. a samplesheet that lists the FASTQ files and the strandedness of each sample (`--input`)
2. the genome FASTA and the matching gene annotation GTF (`--fasta`, `--gtf`)
3. optionally a prebuilt HISAT2 index for that genome (`--hisat2_index`)

For a mammalian genome the third point is not really optional, see [Reference genome](#reference-genome).

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 4 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Multiple runs of the same sample

The `sample` identifiers have to be the same when you have re-sequenced the same sample more than once e.g. to increase sequencing depth. The pipeline will concatenate the raw reads before performing any downstream analysis. Below is an example for the same sample sequenced across 3 lanes:

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,reverse
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz,reverse
CONTROL_REP1,AEG588A1_S1_L004_R1_001.fastq.gz,AEG588A1_S1_L004_R2_001.fastq.gz,reverse
```

All runs of one sample are concatenated into a single file per read direction, so they have to be of the same type. The pipeline stops with an error if the runs of a sample mix single and paired end data, or if they have different strandedness.

### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet: if `fastq_2` is empty, the sample is single end. The column itself has to stay in the file, so single end rows have two commas in a row.

A final samplesheet file consisting of both single- and paired-end data may look something like the one below. This is for 6 samples, where `TREATMENT_REP3` has been sequenced twice.

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,reverse
CONTROL_REP2,AEG588A2_S2_L002_R1_001.fastq.gz,AEG588A2_S2_L002_R2_001.fastq.gz,reverse
CONTROL_REP3,AEG588A3_S3_L002_R1_001.fastq.gz,AEG588A3_S3_L002_R2_001.fastq.gz,reverse
TREATMENT_REP1,AEG588A4_S4_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP2,AEG588A5_S5_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP3,AEG588A6_S6_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP3,AEG588A6_S6_L004_R1_001.fastq.gz,,reverse
```

| Column         | Description                                                                                                                                                                                  |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`       | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. It cannot contain spaces.                                                      |
| `fastq_1`      | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                                   |
| `fastq_2`      | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz". Leave empty for single end data.                                  |
| `strandedness` | Library strandedness: `forward`, `reverse` or `unstranded`. Must be the same for all runs of a sample. Most current Illumina stranded kits (e.g. TruSeq Stranded, dUTP based) are `reverse`. |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

### Finding out the strandedness

The pipeline does not infer strandedness on its own, it has to be given in the samplesheet. After the alignment RSeQC checks it against the data and prints a warning when they do not match (see [output](output.md#rseqc)). It decides which strand flags HISAT2 (`--rna-strandness`), StringTie (`--rf` / `--fr`) and featureCounts (-s) get, so a wrong value does not crash the run but silently assigns reads to the wrong strand. Ways to find it:

- the documentation of the library prep kit, or the methods section of the paper the data comes from
- a quick [Salmon](https://salmon.readthedocs.io/) run with `--libType A` on a subset of reads: the `expected_format` in `lib_format_counts.json` is `ISR` for `reverse`, `ISF` for `forward` and `IU` for `unstranded` paired end data (`SR`, `SF`, `U` for single end)
- the strandedness check of a previous nf-core/rnaseq run on the same data

For the data we tested on (GSE223541, mouse dorsal root ganglia) Salmon reported `ISR`, so those samples are `reverse`.

## Reference genome

| Parameter        | Required | Description                                                                                      |
| ---------------- | -------- | ------------------------------------------------------------------------------------------------ |
| `--fasta`        | yes      | Genome sequence in FASTA format.                                                                 |
| `--gtf`          | yes      | Gene annotation in GTF format. StringTie and featureCounts only quantifiy the genes listed here. |
| `--hisat2_index` | no       | Prebuilt HISAT2 index, either as a directory or as a `.tar.gz` archive of one.                   |

FASTA, GTF and index have to come from the same genome release and use the same chromosome names. A GTF from Ensembl (`1`, `2`, ...) does not match a FASTA from UCSC (`chr1`, `chr2`, ...): the alignment still runs, but no read overlaps a gene and every TPM is 0.

If `--hisat2_index` is not given, the pipeline builds the index from `--fasta` and `--gtf`. That is fine for small genomes like the test data. For mouse or human it is not: building a splice aware HISAT2 index needs far more memory than aligning against it, and the pipeline then falls back to an index without splice sites. For those genomes, build the index once (or download one) and pass it with `--hisat2_index`. The directory has to contain the `*.ht2` files, their common prefix does not matter.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run SaveTheWhaIes/cwbd-project \
    -profile docker \
    --input ./samplesheet.csv \
    --fasta ./reference/genome.fa \
    --gtf ./reference/genes.gtf \
    --hisat2_index ./reference/hisat2 \
    --outdir ./results
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles. The main result is `results/tpm/gene_tpm.tsv` and `results/counts/gene_counts.tsv`, see the [output documentation](output.md) for all files.

As an example, this is the run on two mouse samples of GSE223541 against GRCm39 (Ensembl release 116), on a machine with 12 CPUs and 15 GB of memory:

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2,strandedness
SNI_Oxy_H2,fastq/SRX19144486_SRR23195516_1.fastq.gz,fastq/SRX19144486_SRR23195516_2.fastq.gz,reverse
Sham_Oxy_C3,fastq/SRX19144488_SRR23195511_1.fastq.gz,fastq/SRX19144488_SRR23195511_2.fastq.gz,reverse
```

```bash
nextflow run SaveTheWhaIes/cwbd-project -r 1.0.0 \
    -profile docker \
    --input samplesheet.csv \
    --fasta reference/Mus_musculus.GRCm39.dna.primary_assembly.fa \
    --gtf reference/Mus_musculus.GRCm39.116.gtf \
    --hisat2_index reference/hisat2 \
    --outdir results
```

The FASTQ files were downloaded with [nf-core/fetchngs](https://nf-co.re/fetchngs) from the run accessions.

### Test profiles

Two test profiles run the whole pipeline on small public datasets, without any input of your own:

```bash
nextflow run SaveTheWhaIes/cwbd-project -profile test,docker --outdir results_test
nextflow run SaveTheWhaIes/cwbd-project -profile test_human,docker --outdir results_test_human
```

| Profile      | Data                                                                                                      | What it covers                                                                                  |
| ------------ | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `test`       | Yeast, GSE110004 from the nf-core/rnaseq test data. 4 samples, 6 runs, paired and single end, `reverse`.  | Concatenating runs, mixed single and paired end, building the HISAT2 index.                     |
| `test_human` | Human, one paired end sample on a 40 kb piece of chromosome 22 (nf-core modules test data), `unstranded`. | A second organism with spliced genes, unstranded data, a TPM table with a single sample column. |

The test data is only meant to check that the pipeline works, the expression values have no biological meaning. In `test_human`, for example, almost all reads fall into a single gene, so that gene gets nearly the whole 1,000,000 TPM.

The same two cases plus a run with a prebuilt index (`--hisat2_index` as `.tar.gz`) are set up as [nf-test](https://www.nf-test.com) tests in `tests/`. They compare all outputs with stored snapshots:

```bash
nf-test test --profile +docker
```

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run SaveTheWhaIes/cwbd-project -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: "./samplesheet.csv"
fasta: "./reference/genome.fa"
gtf: "./reference/genes.gtf"
hisat2_index: "./reference/hisat2"
outdir: "./results/"
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull SaveTheWhaIes/cwbd-project
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [SaveTheWhaIes/cwbd-project releases page](https://github.com/SaveTheWhaIes/cwbd-project/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `test_human`
  - A second test profile on human chromosome 22 data, see [Test profiles](#test-profiles)
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow `24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
