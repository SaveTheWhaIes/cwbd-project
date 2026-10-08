#!/usr/bin/env python3
"""
Merges the StringTie gene abundance tables into one genes x samples TPM table.

Input: StringTie -A gene abudance files (one per sample)
Output: TSV with gene_id, gene_name and TPM values for each sample
"""

# packages
import argparse
import csv
from pathlib import Path

# constants
SUFFIX = ".gene.abundance.txt"

# returns TPM and gene name per gene ID for one sample
def read_sample(path):

    # the twwo dictionaries to return
    tpm = {}
    names = {}

    with open(path, newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            gene = row["Gene ID"]
            tpm[gene] = tpm.get(gene, 0.0) + float(row["TPM"])
            names[gene] = row["Gene Name"]
    return tpm, names


def main():

    # parse arguments
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("abundances", nargs="+", type=Path, help=f"StringTie gene abundance files named <sample>{SUFFIX}")
    parser.add_argument("--output", required=True, type=Path, help="Output TSV")
    args = parser.parse_args()

    # read all samples and merge into one table
    samples = []
    tpm_by_sample = {}
    gene_names = {}
    for path in sorted(args.abundances):
        sample = path.name.removesuffix(SUFFIX)
        tpm, names = read_sample(path)
        samples.append(sample)
        tpm_by_sample[sample] = tpm
        gene_names.update(names)

    with open(args.output, "w", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(["gene_id", "gene_name"] + samples)
        for gene in sorted(gene_names):
            writer.writerow([gene, gene_names[gene]] + [f"{tpm_by_sample[s].get(gene, 0.0):.6f}" for s in samples])


if __name__ == "__main__":
    main()
