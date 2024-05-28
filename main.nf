#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { map_reads; make_report } from './modules/local/laava'

NO_FILE = file("$projectDir/bin/NO_FILE")

workflow laava {
    take:
    reads
    vector_fa
    packaging_fa
    host_fa
    repcap_name
    vector_bed
    vector_type,
    target_gap_threshold
    max_allowed_outside_vector
    max_allowed_missing_flanking
    flipflop
    main:

    map_reads(reads,combine(vector_fa).combine(packaging_fa).combine(host_fa).combine(repcap_name))

    make_report( map_reads.out.mapped_reads.combine(vector_bed).combine(vector_type).combine(target_gap_threshold).combine(max_allowed_outside_vector).combine(max_allowed_missing_flanking).combine(flipflop))
    emit:
    sam = map_reads.out.mapped_reads
    per_read_csv = make_report.out.per_read_csv
    summary_csv = make_report.out.summary_csv
    nonmatch_stat_csvgz = make_report.out.nonmatch_stat_csvgz
    tagged_bam = make_report.out.tagged_bam
    subtype_bams = make_report.out.subtype_bams
    subtype_bais = make_report.out.subtype_bais
    flipflop_assignments_txt = make_report.out.flipflop_assignments_txt
    flipflop_bams = make_report.out.flipflop_bams
    alignments_tsv = make_report.out.alignments_tsv
    readsummary_tsv = make_report.out.readsummary_tsv
    sequence_error_tsv = make_report.out.sequence_error_tsv
    flipflop_tsv = make_report.out.flipflop_tsv
    rdata = make_report.out.rdata
}

workflow {
    seqfiles = Channel.fromPath(params.seq_reads).map { file -> tuple( file.getName().split(/\.fq|\.fastq/)[0],file ) }
    if (params.flipflop_fa) {
        flipflop=Channel.fromPath("${params.flipflop_fa}", checkIfExists: true).map { file -> tuple( file.getName().split(/\.fq|\.fastq/)[0],file ) }
    } else {
        flipflop=Channel.of(tuple("NO_FILE", NO_FILE))
    }
    laava(seqfiles,Channel.fromPath(params.vector_fa),params.packaging_fa ? Channel.fromPath(params.packaging_fa) : NO_FILE, params.host_fa ? Channel.fromPath(params.host_fa): NO_FILE,params.repcap_name,Channel.fromPath(params.vector_bed),params.vector_type,params.target_gap_threshold, params.max_allowed_outside_vector,params.max_allowed_missing_flanking,flipflop)
}