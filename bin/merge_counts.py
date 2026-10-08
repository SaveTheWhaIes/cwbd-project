#!/usr/bin/env python3
"""
Merges the featureCounts tables into one genes x samples read count table.

Input: featureCounts tables (one per sample), run with --extraAttributes gene_name
Output: TSV with gene_id, gene_name and the read counts for each sample
"""

# packages
import argparse
import csv
from pathlib import Path

# constants
SUFFIX = ".featureCounts.tsv"

# returns the count and gene name per gene ID for one sample
def read_sample(path):

    # the two dictionaries to return
    counts = {}
    names = {}

    with open(path, newline="") as fh:
        # the first line is a comment with the featureCounts command
        next(fh)
        for row in csv.DictReader(fh, delimiter="\t"):
            gene = row["Geneid"]
            # the last column holds the counts, its header is the BAM file name
            counts[gene] = int(list(row.values())[-1])
            names[gene] = row["gene_name"]
    return counts, names


def main():

    # parse argum
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("counts", nargs="+", type=Path, help=f"featureCounts tables named <sample>{SUFFIX}")
    parser.add_argument("--output", required=True, type=Path, help="Output TSV")
    args = parser.parse_args()

    # read all sale
    samples = []
    counts_by_sample = {}
    gene_names = {}
    for path in sorted(args.counts):
        sample = path.name.removesuffix(SUFFIX)
        counts, names = read_sample(path)
        samples.append(sample)
        counts_by_sample[sample] = counts
        gene_names.update(names)

    with open(args.output, "w", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(["GeneID", "GeneName"] + samples)
        for gene in sorted(gene_names):
            writer.writerow([gene, gene_names[gene]] + [counts_by_sample[s].get(gene, 0) for s in samples])


if __name__ == "__main__":
    main()
