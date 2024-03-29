# ERVmap
ERVmap is one part curated database of human proviral ERV loci and one part a stringent algorithm to determine which ERVs are transcribed in RNA seq data.

# **Citation**
Tokuyama M. et. al., ERVmap analysis reveals genome-wide transcription of human endogenous retroviruses. Proc Natl Acad Sci U S A. 2018 Dec 11;115(50):12565-12572. doi: 10.1073/pnas.1814589115.

# **What's new?**
ERVmap 1.1 includes:
* The introduction of ERVmap auto, to allow easy processing of multiple files
* Descriptive error catching for incorrect arguments
* Thorough documentation for easier setup and use
* Improved folder structure
* Bug fixes
 
Also keep an eye out for ERVmap 2, featuring updated dependencies and cleaner architecture. Coming soon.
# **Installing**

### Install dependencies
```
bedtools 2.29.2
btrim 0.3.0 (http://graphics.med.yale.edu/trim/)
bwa 0.7.17
cufflinks 2.2.1
perl 5.26
python 2.7.16
R 3.6.2
samtools 1.9
tophat 2.1.1
bowtie 2.4.2
```
### Install required libraries
```
htseq 0.11.3 for Python
File::Type 0.22 for Perl
DESeq 1.38.0 for R (via BiocManager)
```

### Install .pl and r files
```
erv_genome.pl
interleaved.pl
run_clean_htseq.pl
clean_htseq.pl
merge_count.pl
normalize_with_file.pl
normalize_deseq.r
```
### Gather and generate reference files
|File|Possible source| Suggested file location|
|----------------------------------------|------------------------------------------------------|-----------------------------------------------------------|
|HG38 primary assembly fasta|[ensembl](https://ensembl.org/Homo_sapiens/Info/Index)| ref/Bowtie2_genome/genome.fa AND ref/bwa_genome/genome.fa|
|HG38 comprehensive gene annotation (gtf)|[ensembl](https://ensembl.org/Homo_sapiens/Info/Index)| ref/genes.gtf| 
|ERV bed |Included|ref/ERVmap.bed|                                |Bowtie and BWA index files|**Manually generated** (see below)|ref/Bowtie2_genome, ref/bwa_genome|
|Illumina Adapter|Included*|ref/illumina_adapter.txt|
|Genome file|Included|ref/GRCh38.genome_file.txt|                     
|Bowtie transcriptome files|Autogenerated (see below)|ref/Bowtie2_genome/known|

*Oligonucleotide sequences © 2021 Illumina, Inc. All rights reserved.

Index files must be generated manually before the first run if not already generated:
* **BWA index files**: `bwa index -p ref/bwa_genome/genome ref/bwa_genome/genome.fa`
* **Bowtie index files**: `bowtie2-build ref/Bowtie2_genome/genome.fa ref/Bowtie2_genome/genome`

Transcriptome files are normally auto-generated on the first run of ERVmap. However, if ERVmap is unable to generate the transcriptome files (e.g. on a server with limited write permissions for computational nodes), the transcriptome can be manually generated with the following code after generating the Bowtie index files:
`tophat2 -G ref/genes.gtf --transcriptome-index=Bowtie2_genome/known Bowtie2_genome/genome`
# **Map data to human genome (hg38)**
Running the below blocks of code in the terminal will yield raw counts for cellular genes and ERVmap loci as separate files.

### Setup for pair-end
Skip the following step for single end data
```
interleaved.pl --read1  my_file_R1.fastq.gz  --read2 my_file_R2.fastq.gz > my_file.fastq
```
The above will convert `my_file_R1.fastq.gz` and `my_file_R2.fastq.gz` into one file, `my_file.fastq`
### Define file locations
Modify the below lines of code for your particular data and folder structure
```
dataset_name=my_data #used for creating unique directory names

input_file=/path/to/my_file.fastq.gz #absolute path to file

ref=~/ERVmap/ref #folder containing required reference files (see below)
scripts=~/ERVmap/scripts #folder containing included perl and R scripts
```
### Map data
```
$scripts/erv_genome.pl -start_stage 1 -end_stage 6 \
--fastq $input_file \
--genome $ref/bwa_genome/genome \
--genome_Bowtie2 $ref/Bowtie2_genome/genome \
--bed $ref/ERVmap.bed \
--genomefile $ref/GRCh38.genome_file.txt \
--gtf $ref/genes.gtf \
--transcriptome $ref/Bowtie2_genome/known \
--adaptor $ref/illumina_adapter.txt \
--filter $scripts/parse_bam.pl \
--cell ${dataset_name}_working
```
Note that if btrim, tophat2, bwa, samtools, or bedtools are not in your path variable, they will have to be specified as arguments as well. (if unsure, check with `type <program>`)
### Store output files
```
output_folder=./output/$dataset_name

mkdir -p $output_folder/erv $output_folder/cellular

input_name=${input_file##*/}
input_name=${input_name%%.*}

mv ./${dataset_name}_working/herv_coverage_GRCh38_genome.txt $output_folder/erv/${input_name}.e
mv ./${dataset_name}_working/GRCh38/htseq.cnt $output_folder/cellular/${input_name}.c
```
**Repeat the above steps for all the input samples.** 
# **Clean up data, merge, and normalize**

These steps will yield normalized ERV read counts based on size factors obtained through DESeq analysis.
Use the output files from above.
```
$scripts/run_clean_htseq.pl $output_folder/cellular c c2 __ $scripts
$scripts/merge_count.pl 3 6 e $output_folder/erv > $output_folder/erv/merged_erv.txt
$scripts/merge_count.pl 0 1 c2 $output_folder/cellular > $output_folder/cellular/merged_cellular.txt
$scripts/normalize_deseq.r  $output_folder/cellular/merged_cellular.txt $output_folder/cellular/normalized_cellular.txt $output_folder/cellular/normalized_factors.txt
$scripts/normalize_with_file.pl $output_folder/cellular/normalized_factors.txt $output_folder/erv/merged_erv.txt > $output_folder/full_normalized_erv_counts.txt
```
# **ERVmap auto**
Also included in this github is ERVmap auto. After installing dependencies and gathering reference files, ERVmap auto allows you to run the above code on all appropriately named fastq files in a specified directory.
If installation is completed with files and directories named as specified above, and with the ERVmap base directory in your home folder (`~`) this will work as-is. **Otherwise, you will need to edit ERVmap_auto.sh to work with your folder structure.**

To use, place all fastq files in an input folder, with the following names:
* Single end data as \<name>_SS.fastq.gz
* First reads of pair-end data as \<name>_R1.fastq.gz
* Second reads of pair-end data as \<name>_R2.fastq.gz

Then run `bash ERVmap_auto.sh <input_folder>`
# **Interpreting results**
This will output the following files of interest in the specified output folder:
* **full_normalized_erv_counts.txt**:  a tab-separated table of ERV counts across all samples, normalized to size factors based on cellular gene count using DEseq
* **merged_erv.txt**: a tab-separated table of un-normalized ERV counts across all samples
* **normalized_cellular.txt**: a space-separated table of cellular gene counts across all samples, normalized using DEseq
* **merged_cellular.txt**: a space-separated table of un-normalized cellular gene counts across all samples
* **normalized_factors.txt**: a tab-separated table containing the factors used to normalize each of the input samples


# **Authors**

* Maria Tokuyama
* Thomas Deckers
* Eric Liu
* Yong Kong


