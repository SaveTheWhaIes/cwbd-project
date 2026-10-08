# SaveTheWhaIes/cwbd-project: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.1dev - [unreleased]

### `Added`

- [#17](https://github.com/SaveTheWhaIes/cwbd-project/pull/17) added animated metro map.
- [#19](https://github.com/SaveTheWhaIes/cwbd-project/pull/19) Gene level read counts with featureCounts, merged into one genes x samples table by the local module MERGE_COUNTS, featureCounts summary in MultiQC.
- [#19](https://github.com/SaveTheWhaIes/cwbd-project/pull/19) Metro map v4: TPM and read counts in one Quantification section, QC line replaced by stations on the main route as in nf-core/rnaseq.

### `Fixed`

- [#16](https://github.com/SaveTheWhaIes/cwbd-project/pull/16) Metro map rewritten by hand from `docs/images/metro.mmd`.
- [#19](https://github.com/SaveTheWhaIes/cwbd-project/pull/19) Trailing whitespace and prettier formatting, so the pre-commit lint passes again.
- [#19](https://github.com/SaveTheWhaIes/cwbd-project/pull/19) MultiQC merges the FastQC rows of read 1 and read 2 into the sample row of the General Statistics table.

## v1.0.0 - [2026-10-07]

Initial release of SaveTheWhaIes/cwbd-project, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- [#2](https://github.com/SaveTheWhaIes/cwbd-project/pull/2) QC_TRIM subworkflow: merges runs of the same sample, runs FastQC on the raw reads and trims adapters and low quality bases with fastp.
- [#3](https://github.com/SaveTheWhaIes/cwbd-project/pull/3) Samplesheet column `strandedness` (`forward`, `reverse`, `unstranded`), checked to be the same for all runs of a sample.
- [#3](https://github.com/SaveTheWhaIes/cwbd-project/pull/3) Reference parameters `--fasta`, `--gtf` and `--hisat2_index`.
- [#4](https://github.com/SaveTheWhaIes/cwbd-project/pull/4) ALIGN subworkflow: HISAT2 alignment (index built from `--fasta`/`--gtf` unless `--hisat2_index` is given), coordinate sorting and indexing with SAMtools.
- [#3](https://github.com/SaveTheWhaIes/cwbd-project/pull/3) Test profile on the nf-core/rnaseq yeast test data (GSE110004) and nf-test snapshot of the test run.
- [#5](https://github.com/SaveTheWhaIes/cwbd-project/pull/5) MARKDUP subworkflow: Picard MarkDuplicates flags duplicate reads and reports duplication metrics to MultiQC.
- [#6](https://github.com/SaveTheWhaIes/cwbd-project/pull/6) QUANTIFY subworkflow: gene level TPM per sample with StringTie (`-e`, strandedness from the samplesheet), merged into one genes x samples table by the local module MERGE_TPM.
- [#7](https://github.com/SaveTheWhaIes/cwbd-project/pull/7) Human chromosome 22 test.
- [#8](https://github.com/SaveTheWhaIes/cwbd-project/pull/8) HISAT2 index input and test.
- [#9](https://github.com/SaveTheWhaIes/cwbd-project/pull/9) Add annotations, comments and update docs.
- [#10](https://github.com/SaveTheWhaIes/cwbd-project/pull/10) Add nf-metro map

### `Fixed`

- [#1](https://github.com/SaveTheWhaIes/cwbd-project/pull/1) Repository name `cwbd-project` used throughout the template, default branch `main`.
- [#11](https://github.com/SaveTheWhaIes/cwbd-project/pull/11) hopefully fixed results ignoring + moved MERGE_TPM environment.yml.

### `Dependencies`

| Dependency  | Old version | New version |
| ----------- | ----------- | ----------- |
| `fastqc`    |             | 0.12.1      |
| `fastp`     |             | 1.3.6       |
| `hisat2`    |             | 2.2.3       |
| `samtools`  |             | 1.24        |
| `picard`    |             | 3.5.0       |
| `multiqc`   |             | 1.35        |
| `stringtie` |             | 3.0.3       |
| `python`    |             | 3.14.5      |
| `tar`       |             | 1.34        |
