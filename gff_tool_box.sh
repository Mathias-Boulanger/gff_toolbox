#!/bin/bash
#Made by Mathias Boulanger - 2019/02/14
#gff_tool_box.sh
#version 1.0
#use on gff file structure

ARGS=1				#The script need 1 argument
NAMEPROG=$0			#Name of the programme
DATA=$1				#File in argument
EXTENSION="gff"		#Extension file necessary to run this script
SPIN='-\|/'			#Waiting characters

##Check the ability to work
if [[ $# -ne $ARGS ]]; then
    printf "%s\n" "Usage: ${NAMEPROG##*/} target_file.gff" ""
    exit 1
elif [[ ! -f $DATA ]];then
	printf "%s\n" "Error: the file '${DATA}' does not exit!" "Please use an existing file." "Usage: ${NAMEPROG##*/} target_file.gff" ""
	exit 1
elif [[ $(wc -l $DATA) = "0 ${DATA}" ]]; then
	printf "%s\n" "Error: your file is empty!" "Usage: ${NAMEPROG##*/} target_file.gff" ""
	exit 1
elif [[ $(awk '{FS="\t"}{print NF}' $DATA | uniq | wc -l) -ne 1  ]]; then
	printf "%s\n" "Error: some lines of your file does not present 9 columns!" ""
elif [[ $(awk '{FS="\t"}{print NF}' $DATA | uniq) -ne 9 ]]; then
	printf
fi

##Start to work
printf "\033c"
if [[ ${DATA##*.} != $EXTENSION ]]; then
	printf "%s\n" "" "WARNING: The file extension sould be ."$EXTENSION "Make sure that your file present an gff structure."
fi
printf "%s\n" "" "Year, let's sort gff files..." ""
r=0
while true; do
	while true; do
		#Remind of gff struture
		HEADER="%-10s\t %-10s\t %-14s\t %-5s\t %-5s\t %-5s\t %-6s\t %-12s\t %-66s\n"
		STRUCTURE="%-10s\t %-10s\t %-14s\t %5d\t %5d\t %-5s\t %-6s\t %-12s\t %-66s\n"
		divider=======================================================================================
		divider=$divider$divider$divider
		width=162
		printf "%s\n" "" "Classical gff file sould present the structure as follow:" ""
		printf "$HEADER" "SeqID" "Source" "Feature (type)" "Start" "End" "Score" "Strand" "Frame (Phase)" "Attributes"
		printf "%$width.${width}s\n" "$divider"
		printf "$STRUCTURE" \
		"NC_XXXXXX" "RefSeq" "gene" "1" "1728" "." "+" "." "ID=geneX;...;gbkey=Gene;gene=XXX;gene_biotype=coding_protein;..." \
		"chrX" "." "exon" "1235" "1298" "." "-" "." "ID=idX;...;gbkey=misc_RNA;gene=XXX;...;..." \
		"NC_XXXXXX" "BestRefSeq" "CDS" "50" "7500" "." "+" "1" "ID=idX;...;gbkey=CDS;gene=XXX;...;..."
		printf "%s\n" "" "If you would like more informations on gff file structure visit this web site: http://gmod.org/wiki/GFF3" ""
		
		#choice0: TOOL BOX

		printf "%s\n" "" "Which tool do you would like to use on ${DATA} ?" "" 
		printf "%s\n" "=============== Tools specific to human genome sorting ===============" ""
		printf "%s\n" "1 - Classical Human Chromosomes sorter" "2 - GFF to BED file" "3 - Promoter regions extractor (in development)" ""
		printf "%s\n" "======================= Tools to sort gff file =======================" ""
		printf "%s\n" "3 - Sort by sources present in my file (column 2)" "4 - Sort by type of region present in my file (column 3)" "5 - Sort by attributes (IDs, gbkey, biotype, specific gene) (column 9)" "6 - Gene name extractor (in development)" "7 - Isoform inspector (in development)" ""
		printf "%s\n %s\n \r%s" "If you would like to quite, please answer 'q' or 'quite'" "" "Please enter the number of the choosen tool: "
		read ANSWER
		case $ANSWER in
			[1-5] )
				printf "\n"
				t=$ANSWER
				break;;
			[qQ]|[qQ][uU][iI][tT] )
				printf "%s\n" "" "Thank you to use gff tool box !"
				if [[ $r -ne 0 ]]; then
					printf "%s\n" "" "Sorted files has been generated in this directory."				
				fi
				printf "%s\n" "If you got any problems when you used this script or if you have any comments on it, please feel free to contact mathias.boulanger.17@hotmail.com" ""
				exit 0
				;;
			* )
				printf "\033c"
				printf "%s\n" "" "Please answer a tool number or quit." ""
				;;
		esac
	done

	CHRNAMES=( "chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY" "chrM" )
	NCNAMES=( "NC_000001.10" "NC_000002.11" "NC_000003.11" "NC_000004.11" "NC_000005.9" "NC_000006.11" "NC_000007.13" "NC_000008.10" "NC_000009.11" "NC_000010.10" "NC_000011.9" "NC_000012.11" "NC_000013.10" "NC_000014.8" "NC_000015.9" "NC_000016.9" "NC_000017.10" "NC_000018.9" "NC_000019.9" "NC_000020.10" "NC_000021.8" "NC_000022.10" "NC_000023.10" "NC_000024.9" "NC_012920.1" )

	##Tool1: Classical Human Chromosomes sorter
	while true; do
		if [[ t -eq 1 ]]; then
			if [[ $(grep "^NC" $DATA | wc -l) -eq 0 && $(grep "^chr" $DATA | wc -l) -eq 0 ]]; then
				printf "\033c"
				printf "%s\n" "Error: Your file does not contain classical human chromosome names (NC_XXXXXX or chrX)!" ""
				break
			elif [[ $(grep "^NC" $DATA | wc -l) -gt 0 && $(grep "^chr" $DATA | wc -l) -gt 0 ]]; then
				while true; do
					printf "%s\n" "Names of human chromosomes in your file are named by 2 different ways ('NC_XXXXXX' and 'chrX')" "Which name do you want to keep in your gff file to homogenize the chromosome SeqIDs? (NC or chr)" 
					read ANSWER
					printf "\n"
					x=1			
					case $ANSWER in
						[nN][cC] )
							SORTCHR="^NC"
							NAMEFILE1=${DATA%%.*}_formatNC.$EXTENSION
							if [[ -f $NAMEFILE1 ]]; then
								while true; do
									printf "\n"
									printf "The directory already present a file ("$NAMEFILE1") homogenized by NC.\nDo you want to overwrite this file? (Y/n)\n"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] ) 
											cp $DATA $NAMEFILE1
											for i in $(seq 0 24) ; do
												A="${NCNAMES[$i]}"
												B="${CHRNAMES[$i]}"
												awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$B'") print "'$A'", $2, $3, $4, $5, $6, $7, $8, $9; if ($1!="'$B'") print $0}' $NAMEFILE1 > .${NAMEFILE1}.tmp && mv .${NAMEFILE1}.tmp $NAMEFILE1
											done & PID=$!								
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rHomogenization of your file by 'NC' ${SPIN:$i:1}"
												sleep .1
											done
											printf "%s\n" "" "" "Your file has been re-homogenize by 'NC' chromosome names." ""
											break;;
										[nN][oO]|[nN] )
											printf "%s\n" "" "Ok, the file already present in your directory will be use for the next steps." ""
											break;;				
				       					* ) 
											printf "\033c"
											printf "%s\n" "" "Please answer yes or no." "";;
				    				esac
								done
							else
								cp $DATA $NAMEFILE1
								for i in $(seq 0 24) ; do
									A="${NCNAMES[$i]}"
									B="${CHRNAMES[$i]}"
									awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$B'") print "'$A'", $2, $3, $4, $5, $6, $7, $8, $9; if ($1!="'$B'") print $0}' $NAMEFILE1 > .${NAMEFILE1}.tmp && mv .${NAMEFILE1}.tmp $NAMEFILE1
								done & PID=$!								
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rHomogenization of your file by 'NC' ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "Your file has been homogenize by 'NC' chromosome names." ""
							fi
							break;;
						[cC][hH][rR] )
							SORTCHR="^chr"
							NAMEFILE1=${DATA%%.*}_formatChr.$EXTENSION
							if [[ -f $NAMEFILE1 ]]; then
								while true; do
									printf "\n"
									printf "The directory already present a file ("$NAMEFILE1") homogenized by NC.\nDo you want to overwrite this file? (Y/n)\n"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] ) 
											cp $DATA $NAMEFILE1
											for i in $(seq 0 24) ; do
												A="${NCNAMES[$i]}"
												B="${CHRNAMES[$i]}"
												awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6, $7, $8, $9; if ($1!="'$A'") print $0}' $NAMEFILE1 > .${NAMEFILE1}.tmp && mv .${NAMEFILE1}.tmp $NAMEFILE1
											done & PID=$!								
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rHomogenization of your file by 'chr' ${SPIN:$i:1}"
												sleep .1
											done		
											printf "%s\n" "" "" "Your file has been re-homogenize by 'chr' chromosome names." ""
											break;;
										[nN][oO]|[nN] )
											printf "%s\n" "" "Ok, the file already present in your directory will be use for the next steps." ""
											break;;				
				       					* ) 
											printf "\033c"
											printf "%s\n" "" "Please answer yes or no." "";;
				    				esac
								done
							else
								cp $DATA $NAMEFILE1
								for i in $(seq 0 24) ; do
									A="${NCNAMES[$i]}"
									B="${CHRNAMES[$i]}"
									awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6, $7, $8, $9; if ($1!="'$A'") print $0}' $NAMEFILE1 > .${NAMEFILE1}.tmp && mv .${NAMEFILE1}.tmp $NAMEFILE1
								done & PID=$!								
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rHomogenization of your file by 'chr' ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "Your file has been homogenize by 'chr' chromosome names." ""
							fi
							break;;				
							* ) 
							printf "\033c"
							printf "%s\n" "" "Please answer NC or chr." "";;
					esac
				done
			elif [[ $(grep "^NC" $DATA | wc -l) -eq 0 && $(grep "^chr" $DATA | wc -l) -gt 0 ]]; then
				SORTCHR="^chr"
			elif [[ $(grep "^NC" $DATA | wc -l) -gt 0 && $(grep "^chr" $DATA | wc -l) -eq 0 ]]; then
				SORTCHR="^NC"
			fi
			printf "\n"
			if [[ $x -eq  0 ]]; then
				NAMEFILE2=${DATA%%.*}_mainChrom.$EXTENSION
				DATA=${DATA}
			elif [[ $x -eq  1 ]]; then
				NAMEFILE2=${NAMEFILE1%%.*}_mainChrom.$EXTENSION
				DATA=${NAMEFILE1}
			fi			
			if [[ -f $NAMEFILE2 ]]; then
				while true; do
					printf "\n"
					printf "The directory already present a file ("$NAMEFILE2") sorted by main chromosomes.\nDo you want to sort again? (Y/n)\n"
					read ANSWER
					printf "\n"
					case $ANSWER in
						[yY][eE][sS]|[yY] ) 
							grep "$SORTCHR" $DATA > $NAMEFILE2 & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by main human chromosomes in process ${SPIN:$i:1}"
								sleep .1
							done
							printf "\n"
							printf "%s\n" "" "Your file has been re-sorted by the main human chromosomes." ""
							break;;
						[nN][oO]|[nN] )
							printf "%s\n" "" "Ok, the file already present in your directory will be use for the next steps." ""
							DATA=${NAMEFILE2}
							break;;				
						* ) 
							printf "\033c"
							printf "%s\n" "" "Please answer yes or no." "";;
					esac
				done
			else
				grep "$SORTCHR" $DATA > $NAMEFILE2 & PID=$!
				i=0 &
				while kill -0 $PID 2>/dev/null; do
					i=$(( (i+1) %4 ))
					printf "\rSorting by main human chromosomes ${SPIN:$i:1}"
					sleep .1
				done
				printf "\n"
				printf "%s\n" "" "" "Your file has been sorted by the main human chromosomes." ""
			fi
			r=$r+1
			printf $r "\n"
			DATA=${NAMEFILE2}
			break
		fi
	done

	##Tool2: GFF to BED file
	while true; do
		if [[ t -eq 2 ]]; then
			printf
			r=$r+1
			DATA=${NAMEFILE}
		fi
	done


	##Tool3: Promoter regions extractor (in development)
	while true; do
		if [[ t -eq 3 ]]; then
			printf
			r=$r+1
			DATA=${NAMEFILE}
		fi
	done


	##Tool4: Sort by sources present in my file (column 2)
	while true; do
		if [[ t -eq 4 ]]; then
			
			printf "%s\n" "" "This are sources present in your file:" "" "Number_of_line	Source" "$(awk 'BEGIN{FS="\t"}{print$2}' $DATA | sort | uniq -c)" "" &
			awk 'BEGIN{FS="\t";OFS="\t"}{print$2}' $DATA | sort | uniq | sed 's/ /_/g' > .sources.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for sources present in your file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $(wc -l .sources.tmp) = "1 .sources.tmp" ]]; then
				if [[ $(wc -c .sources.tmp) = "1 .sources.tmp" ]]; then #ATTENTION SI 1 SOURCE ET 1 CARATERE = ERROR
					printf "%s\n" "Error: No source has been found!" "Please check if your file present gff structure."
					rm .sources.tmp
					exit 1
				else
					printf "%s\n" "Only 1 source has been found in your file." "You do not need to sort your file by the database source." ""
					rm .sources.tmp
					break
				fi
			else
				NUMOFSOURCES=$(cat .sources.tmp | wc -l)
				for (( i = 1; i < ${NUMOFSOURCES} + 1; i++ )); do
					eval LISTSOURCES[$i-1]="$(sed -n $i'p' .sources.tmp)"
				done
				rm .sources.tmp
			fi
			while true; do
				printf "By which source do you want to sort? (If your source name present space ' ', please use '_' instead)\n"
				read ANSWER 
				for (( i = 0; i < ${NUMOFSOURCES}; i++ )); do
					if [[ $ANSWER = ${LISTSOURCES[$i]} ]]; then
						SOURCETOSORT=${LISTSOURCES[$i]}
					fi
				done
				if [[ -z $SOURCETOSORT ]]; then
					printf "%s\n" "" "The source that you wrote is not find in your file." ""
				else
					printf $SOURCETOSORT > .sourcetosort.tmp				
					SOURCETOSORT2="$(sed 's/_/ /g' .sourcetosort.tmp)"
					rm .sourcetosort.tmp
					NAMEFILE3=${DATA%%.*}_${SOURCETOSORT}Sorted.$EXTENSION
					if [[ -f $NAMEFILE3 ]]; then
					while true; do
						printf "The directory already present a file ("$NAMEFILE3") sorted by ""$SOURCETOSORT2"" \nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY] ) 
							awk 'BEGIN{FS="\t"; OFS="\t"}{ if ($2=="'"$SOURCETOSORT2"'") print $0}' $DATA > $NAMEFILE3 & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by ""$SOURCETOSORT2"" in process ${SPIN:$i:1}"
								sleep .1
							done
							printf "\n"
							printf "Your file has been re-sorted by ""$SOURCETOSORT2""\n""\n"
							break;;
							[nN][oO]|[nN] )
							printf "Ok, the file already present in your directory will be use for the next steps.\n"
							break;;				
		   					* ) 
							printf "%s\n" "" "Please answer yes or no." "";;
						esac
					done
					else
						awk 'BEGIN{FS="\t"; OFS="\t"}{ if ($2=="'"$SOURCETOSORT2"'") print $0}' $DATA > $NAMEFILE3 & PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rSorting by ""$SOURCETOSORT2"" in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\n"
						printf "\n" "Ok, your file has been sorted by the source: " "$SOURCETOSORT2" "\n" "\n"
					fi
					z=2
		    		break
				fi
			done
		


		else
			r=0
			break
		fi
	done

	while true; do
				
	    break
	done

	#Choice3 : Work with annotated file filtered by region features 

	while true; do
		printf "Do you want to work with a specific region feature? (Y/n)\n"
		read ANSWER
		printf "\n"
		case $ANSWER in
			[yY][eE][sS]|[yY] ) 
			if [[ $z -eq 0 ]]; then
				NAMEFILETOSORT=${DATA}
			elif [[ $z -eq 1 ]]; then
				NAMEFILETOSORT=$NAMEFILE2
			elif [[ $z -eq 2 ]]; then
				NAMEFILETOSORT=$NAMEFILE3
			fi
			printf "%s\n" "" "" "This are regions present in your file:" "" "Number_of_line	Region" "$(awk 'BEGIN{FS="\t"}{print$3}' $NAMEFILETOSORT | sort | uniq -c)" "" &
			awk 'BEGIN{FS="\t";OFS="\t"}{print$3}' $NAMEFILETOSORT | sort | uniq | sed 's/ /_/g' > .regions.tmp& PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for region features present in your file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $(wc -l .regions.tmp) = "1 .regions.tmp" ]]; then
				if [[ $(wc -c .regions.tmp) = "1 .regions.tmp" ]]; then
					printf "%s\n" "Error: No region feature has been found!" "Please check if your file present gff structure."
					rm .regions.tmp
					exit 1
				else
					printf "%s\n" "Only 1 region has been found in your file." "You do not need to sort your file by region." ""
					rm .regions.tmp
					break
				fi
			else
				NUMOFREGIONS=$(cat .regions.tmp | wc -l)
				for (( i = 1; i < ${NUMOFREGIONS} + 1; i++ )); do
					eval LISTREGIONS[$i-1]="$(sed -n $i'p' .regions.tmp)"
				done
				rm .regions.tmp
			fi
			while true; do
				printf "\n"
				printf "By which region do you want to sort? (If your region name present space ' ', please use '_' instead)\n"
				read ANSWER
				printf "\n"
				for (( i = 0; i < ${NUMOFREGIONS}; i++ )); do
					if [[ $ANSWER = ${LISTREGIONS[$i]} ]]; then
						REGIONTOSORT=${LISTREGIONS[$i]}
					fi
				done
				if [[ -z $REGIONTOSORT ]]; then
					printf "%s\n" "" "The region that you wrote is not find in your file." ""
				else
					printf $REGIONTOSORT > .regiontosort.tmp
					REGIONTOSORT2="$(sed 's/_/ /g' .regiontosort.tmp)"
					rm .regiontosort.tmp
					NAMEFILE4=${NAMEFILETOSORT%%.*}_${REGIONTOSORT}Sorted.$EXTENSION
					if [[ -f $NAMEFILE4 ]]; then
					while true; do
						printf "The directory already present a file ("$NAMEFILE4") sorted by ""$REGIONTOSORT2"".\nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY] ) 
							awk 'BEGIN{FS="\t";OFS="\t"}{ if ($3=="'"$REGIONTOSORT2"'") print $0}' $NAMEFILETOSORT > $NAMEFILE4 & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by ""$REGIONTOSORT2"" in process ${SPIN:$i:1}"
								sleep .1
							done
							printf "\n"
							printf "\n" "Your file has been re-sorted by ""$REGIONTOSORT2"".\n" "\n"
							break;;
							[nN][oO]|[nN] )
							printf "Ok, the file already present in your directory will be use for the next steps.\n"
							break;;				
	       					* ) 
							printf "%s\n" "" "Please answer yes or no." "";;
	    				esac
					done
					else
						awk 'BEGIN{FS="\t";OFS="\t"}{ if ($3=="'"$REGIONTOSORT2"'") print $0}' $NAMEFILETOSORT > $NAMEFILE4 & PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rSorting by ""$REGIONTOSORT2"" in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\n"
						printf "\n" "Ok, your file has been sorted by the region: ""$REGIONTOSORT2"".\n" "\n" 
					fi
					z=3
	        		break
				fi
			done
			while true; do
				printf "Do you want to create a BED file from your gff file sorted by ""$REGIONTOSORT2""? (Y/n)\n"
				read ANSWER
				printf "\n"
				case $ANSWER in
					[yY][eE][sS]|[yY] )
					while true; do
						printf "%s\n" "Which can of BED to you want to create? (bed3 - bed6 - both)"
						read ANSWER
						case $ANSWER in
							[bB][eE][dD][3] )
							NAMEBED3="${NAMEFILE4%%.*}.bed3"
							if [[ -f $NAMEBED3 ]]; then
								while true; do
									printf "%s\n" "The directory already present a BED3 file ("$NAMEBED3")." "Do you want to overwrite this file? (Y/n)"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] ) 
										awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $NAMEFILE4 > $NAMEBED3
										for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3; if ($1!="'$A'") print $0}' $NAMEBED3 > .${NAMEBED3}.tmp && mv .${NAMEBED3}.tmp $NAMEBED3
										done & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rCreation of BED3 file in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "%s\n" "" "" "The BED3 file has been overwritten." ""
										break;;
										[nN][oO]|[nN] )
										printf "Ok, the BED3 file present in your directory will not be overwritten.\n"
										break;;
										* ) 
										printf "%s\n" "" "Please answer yes or no." "";;
	    							esac
								done
							else
								awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $NAMEFILE4 > $NAMEBED3
								for i in $(seq 0 24) ; do
									A="${NCNAMES[$i]}"
									B="${CHRNAMES[$i]}"
									awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3; if ($1!="'$A'") print $0}' $NAMEBED3 > .${NAMEBED3}.tmp && mv .${NAMEBED3}.tmp $NAMEBED3
								done & PID=$!
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rCreation of BED3 file in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "A BED3 file has been generated." ""
							fi
							break;;
							[bB][eE][dD][6] )
							NAMEBED6="${NAMEFILE4%%.*}.bed6"
							if [[ -f $NAMEBED6 ]]; then
								while true; do
									printf "%s\n" "The directory already present a BED6 file ("$NAMEBED6")." "Do you want to overwrite this file? (Y/n)"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] )
										awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $NAMEFILE4 > $NAMEBED6
										for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6; if ($1!="'$A'") print $0}' $NAMEBED6 > .${NAMEBED6}.tmp && mv .${NAMEBED6}.tmp $NAMEBED6
										done & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rCreation of BED6 file in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "%s\n" "" "" "The BED6 file has been overwritten." ""
										break;;
										[nN][oO]|[nN] )
										printf "Ok, the BED6 file present in your directory will not be overwritten.\n"
										break;;				
	       								* ) 
										printf "%s\n" "" "Please answer yes or no." "";;
	    							esac
								done
							else
								awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $NAMEFILE4 > $NAMEBED6
								for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6; if ($1!="'$A'") print $0}' $NAMEBED6 > .${NAMEBED6}.tmp && mv .${NAMEBED6}.tmp $NAMEBED6
										done & PID=$!

								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rCreation of BED6 file in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "A BED6 file has been generated." ""
							fi
							break;;
							[bB][oO][tT][hH] )
							NAMEBED3="${NAMEFILE4%%.*}.bed3"
							NAMEBED6="${NAMEFILE4%%.*}.bed6"
							if [[ -f $NAMEBED3 ]]; then
								while true; do
									printf "%s\n" "The directory already present a BED3 file ("$NAMEBED3")." "Do you want to overwrite this file? (Y/n)"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] ) 
										awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $NAMEFILE4 > $NAMEBED3
										for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3; if ($1!="'$A'") print $0}' $NAMEBED3 > .${NAMEBED3}.tmp && mv .${NAMEBED3}.tmp $NAMEBED3
										done & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rCreation of BED3 file in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "%s\n" "" "" "The BED3 file has been overwritten." ""
										break;;
										[nN][oO]|[nN] )
										printf "Ok, the BED3 file present in your directory will not be overwritten.\n"
										break;;
										* ) 
										printf "%s\n" "" "Please answer yes or no." "";;
	    							esac
								done
							else
								awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $NAMEFILE4 > $NAMEBED3
								for i in $(seq 0 24) ; do
									A="${NCNAMES[$i]}"
									B="${CHRNAMES[$i]}"
									awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3; if ($1!="'$A'") print $0}' $NAMEBED3 > .${NAMEBED3}.tmp && mv .${NAMEBED3}.tmp $NAMEBED3
								done & PID=$!
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rCreation of BED3 file in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "A BED3 file has been generated." ""
							fi
							if [[ -f $NAMEBED6 ]]; then
								while true; do
									printf "%s\n" "The directory already present a BED6 file ("$NAMEBED6")." "Do you want to overwrite this file? (Y/n)"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY] )
										awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $NAMEFILE4 > $NAMEBED6
										for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6; if ($1!="'$A'") print $0}' $NAMEBED6 > .${NAMEBED6}.tmp && mv .${NAMEBED6}.tmp $NAMEBED6
										done & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rCreation of BED6 file in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "%s\n" "" "" "The BED6 file has been overwritten." ""
										break;;
										[nN][oO]|[nN] )
										printf "Ok, the BED6 file present in your directory will not be overwritten.\n"
										break;;				
	       								* ) 
										printf "%s\n" "" "Please answer yes or no." "";;
	    							esac
								done
							else
								awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $NAMEFILE4 > $NAMEBED6
								for i in $(seq 0 24) ; do
											A="${NCNAMES[$i]}"
											B="${CHRNAMES[$i]}"
											awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$A'") print "'$B'", $2, $3, $4, $5, $6; if ($1!="'$A'") print $0}' $NAMEBED6 > .${NAMEBED6}.tmp && mv .${NAMEBED6}.tmp $NAMEBED6
										done & PID=$!

								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rCreation of BED6 file in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "A BED6 file has been generated." ""
							fi
							break;;		
	       					* ) 
							printf "%s\n" "" "Please answer bed3, bed6 or both." "";;
	    				esac
	    			done				
					break;;
					[nN][oO]|[nN] )
					printf "%s\n" "Ok, BED file will not be generated."
					break;;				
	       			* ) 
					printf "%s\n" "" "Please answer yes or no." "";;
	    		esac
	    	done
	        break;;
	        [nN][oO]|[nN] ) 
			printf "%s\n" "" "Ok, the file will not be sort by region feature." ""
			break;;
	        * ) 
			printf "%s\n" "" "Please answer yes or no." "";;
	    esac
	done
done
