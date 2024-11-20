#!/bin/bash -ex
sample_name=$1
reads=$2
vector_fa=$3
packaging_fa=$4
host_fa=$5

# NOTE: the sequence IDs should be free of blank spaces and symbols. Stick with numbers,
# alphabet letters, and _ and -. If necessary, rename the sequence IDs in the combined
# fasta file.

ls -Alh

# Consolidate inputs, skipping optional files
cp "$vector_fa" all_refs.fa
if [ -e "$packaging_fa" ]; then
    cat "$packaging_fa" >> all_refs.fa
fi
if [ -e "$host_fa" ]; then
    cat "$host_fa" >> all_refs.fa
fi

# Logging
grep '^>' all_refs.fa
echo

if [[ $reads == *.bam ]]; then
    echo "Converting $reads from BAM to FASTQ"
    samtools fastq -n -0 reads.fq "$reads"
    reads_fn=reads.fq
else
    # NB: minimap2 handles .gz automatically
    reads_fn="$reads"
fi

threads=$(nproc)
minimap2 --eqx -a --secondary=no -t $threads all_refs.fa "$reads_fn" > tmp.mapped.sam
# Sort the mapped reads by name
name_sam="$sample_name.sort_by_name.sam"
samtools sort -@ $threads -n -O SAM -o "$name_sam" tmp.mapped.sam

# Make a position-sorted BAM output file for other downstream consumers
pos_bam="$sample_name.sort_by_pos.bam"
# Drop unmapped reads
samtools view -@ $threads --fast -o tmp.sorted.bam tmp.mapped.sam
samtools sort -@ $threads -o "$pos_bam" tmp.sorted.bam
samtools index "$pos_bam"

# Logging
ls -Alh
echo
samtools flagstat "$name_sam"
echo
samtools idxstats "$pos_bam"