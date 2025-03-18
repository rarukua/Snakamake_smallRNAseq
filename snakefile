# Read config file
configfile: "config.yaml"

# Get sample names
SAMPLES = config["samples"]

# Make Snakemake generate all output files
rule all:
    input:
        expand("results/fastqc/{sample}_fastqc.zip", sample=SAMPLES),
        expand("results/fastp/{sample}_fastp.fastq.gz", sample=SAMPLES),
        expand("results/star/{sample}/{sample}_FitReadAligned.out.bam", sample=SAMPLES),
        expand("results/featurecounts/{sample}_counts.txt", sample=SAMPLES)

# FastQC (Before Fastp)
rule fastqc:
    input:
        "/home/GEOdata/GSE83527/FASTQ_files/{sample}.fastq"
    output:
       "results/fastqc/{sample}_fastqc.html",
       "results/fastqc/{sample}_fastqc.zip"
    threads: config["fastqc"]["threads"]
    conda: "workflow/envs/fastqc.yaml"
    shell:
        "mkdir -p results/fastqc && fastqc -t {threads} {input} -o results/fastqc"


# Fastp
rule fastp:
    input:
        "/home/zgao/GEOdata/GSE83527/FASTQ_files/{sample}.fastq"
    output:
        "results/fastp/{sample}_fastp.fastq.gz",
        "results/fastp_reports/{sample}.html",
        "results/fastp_reports/{sample}.json"
    threads: config["fastp"]["threads"]
    conda: "workflow/envs/fastp.yaml"
    shell:
        "mkdir -p results/fastp results/fastp_reports && "
        "fastp -i {input} -o {output[0]} {config[fastp][params]} "
        "--html {output[1]} --json {output[2]}"

# STAR alignment
rule star:
    input:
        "results/fastp/{sample}_fastp.fastq.gz"
    output:
        "results/star/{sample}/{sample}_FitReadAligned.out.bam"
    threads: config["star"]["threads"]
    conda: "workflow/envs/star.yaml"
    shell:
        "mkdir -p results/star/{wildcards.sample} && "
        "STAR --runThreadN {threads} --genomeDir {config[star][index]} "
        "{config[star][params]} {config[star][params2]} {config[star][params3]} "
        "--readFilesCommand zcat --readFilesIn {input} "
        "--sjdbGTFfeatureExon {config[star][sjdbGTFfeatureExon]} "
        "--outFileNamePrefix results/star/{wildcards.sample}/{wildcards.sample}_FitRead"

# FeatureCounts
rule featurecounts:
    input:
        "results/star/{sample}/{sample}_FitReadAligned.out.bam"
    output:
        "results/featurecounts/{sample}_counts.txt"
    threads: config["featurecounts"]["threads"]
    conda: "workflow/envs/featurecounts.yaml"
    shell:
        "mkdir -p results/featurecounts && "
        "featureCounts -t piRbase -F GTF -a {config[featurecounts][gtf]} "
        "-M -O --minOverlap 22 -Q 0 -o {output[0]} {input}"


