# SaveTheWhaIes/cwbd-project: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased<!-- TODO nf-core: replace with date on release -->]

Initial release of SaveTheWhaIes/cwbd-project, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- ALIGN subworkflow: HISAT2 alignment (index built from `--fasta`/`--gtf` unless `--hisat2_index` is given), coordinate sorting and indexing with SAMtools.

### `Fixed`

### `Dependencies`

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| `hisat2`   |             | 2.2.3       |
| `samtools` |             | 1.24        |

### `Deprecated`
