#!/bin/bash

shopt -s extglob
shopt -s nullglob

ref=~/ERVmap/ref #folder containing required reference files (see below)
scripts=~/ERVmap/scripts #folder containing included perl and R scripts

#Main mapping function. Change paths as necessary to match your file structure
map_data () {
	$scripts/erv_genome.pl -start_stage 1 -end_stage 6 \
	--fastq $1 \
	--genome $ref/bwa_genome/genome \
	--genome_Bowtie2 $ref/Bowtie2_genome/genome \
	--bed $ref/ERVmap.bed \
	--genomefile $ref/GRCh38.genome_file.txt \
	--gtf $ref/genes.gtf \
	--transcriptome $ref/Bowtie2_genome/known \
	--adaptor $ref/illumina_adapter.txt \
	--filter $scripts/parse_bam.pl \
	--cell ${workdir}_working

	output_folder=./output/${workdir##*/}

	mkdir -p $output_folder/erv $output_folder/cellular


	mv ${workdir}_working/herv_coverage_GRCh38_genome.txt $output_folder/erv/${1##*/}.e
	mv ${workdir}_working/GRCh38/htseq.cnt $output_folder/cellular/${1##*/}.c
}

#####Argument valdation#####

if [[ "$#" -ne 1 ]]; then
	echo "usage: bash ERVmap_auto.sh input_dir" >&2
	exit 1
fi

workdir=$(readlink -e $1)

#Check if the provided argument is a valid directory
if [ -d "${workdir}" ] ; then
    echo "starting ERVmap on $workdir";
else
    if [ -f "${workdir}" ]; then
        echo "${workdir} is a file. Please provide the path to a directory"\
	 "containing the files you'd like to process.">&2

	exit 1
    else
        echo "${workdir} not found. Please provide a path to a directory"\
 	"containing the files you'd like to process.">&2
        exit 1
    fi
fi

cd $workdir

#Check if appropraitely named files exist
if ! [[ $(ls *@(_SS|_R1|_R2).fastq?(.gz))2>/dev/null  ]]; then
	echo "No appropriately named files found. Please name all single-end reads as"\
	"<name>_SS.fastq.gz and all pair end reads as <name>_R1.fastq.gz or"\
	" <name>_R2.fastq.gz for the first and second reads, respectively.">&2
	exit 1
fi


if [[ $(ls *@(_R1|_R2).fastq?(.gz))2>/dev/null  ]]; then
#Check if pair end files are matched
	failed=0
	#check if each R1 has an R2
	for i in *_R1.fastq?(.gz); do
		filename=${i%_*}
		if ! [ -e ${filename}_R2.fastq?(.gz) ]; then
			echo "${filename}_R2 not found">&2
			failed=1 
		fi
	done
	#Check if each R2 has an R1
	for i in *_R2.fastq?(.gz); do
		filename=${i%_*}
		if ! [ -e ${filename}_R1.fastq?(.gz) ]; then
			echo "${filename}_R1 not found">&2
			failed=1 
		fi
	done
	
	if [ $failed -eq 1 ]; then
        	echo "Ensure that all pair end reads have both reads present."\
        	"Name all single end reads as <name>_SS.fastq.gz">&2
	exit 1; fi
fi

cd -



#####running ERVmap#####
for i in $workdir/*_SS.fastq?(.gz); do
	map_data $i	
done

for i in $workdir/*_R1.fastq?(.gz); do
        $scripts/interleaved.pl --read1 ${i} --read2 ${i/R1.fastq?(.gz)/R2.fastq?(.gz)} > "${i/_R1.fastq?(.gz)/.fastq}"
        map_data ${i/_R1.fastq?(.gz)/.fastq}
done	

$scripts/run_clean_htseq.pl $output_folder/cellular c c2 __ $scripts
$scripts/merge_count.pl 3 6 e $output_folder/erv > $output_folder/erv/merged_erv.txt
$scripts/merge_count.pl 0 1 c2 $output_folder/cellular > $output_folder/cellular/merged_cellular.txt
$scripts/normalize_deseq.r  $output_folder/cellular/merged_cellular.txt $output_folder/cellular/normalized_cellular.txt $output_folder/cellular/normalized_factors.txt
$scripts/normalize_with_file.pl $output_folder/cellular/normalized_factors.txt $output_folder/erv/merged_erv.txt > $output_folder/full_normalized_erv_counts.txt

