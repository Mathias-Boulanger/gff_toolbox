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
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[0;33m'
NOCOLOR='\033[0m'

##Resize the windows
printf '\033[8;40;165t'

##Checking needed commands
printf "Checking for needed commands\n\n"
needed_commands="printf awk sed grep head tail uniq wc rm sleep read kill seq cp mv" ;
req=0
while true; do
	if [[ "$(command -v command)" == "" ]]; then
		printf "\n${ORANGE}WARNING:${NOCOLOR}the command 'command' not found. Check requirements skipped !\n${NAMEPROG##*/} may not works properly!\n"
		break
	else
		for requirement in ${needed_commands}; do
			printf "checking for ${requirement} ... "
			if [[ "$(command -v ${requirement})" == "" ]]; then
				printf "${RED}NOT FOUND!${NOCOLOR}\n"
				((req++))
			else
				printf "${GREEN}OK${NOCOLOR}\n"
			fi			
		done
		printf "\n"
		break
	fi
done
if [[ $req -ne 0 ]]; then
	if [[ $req -eq 1 ]]; then
		printf "\n${RED}Error:${NOCOLOR} ${req} command is missing to execute ${NAMEPROG##*/} properly!\nPlease install it on your system to use ${NAMEPROG##*/}\n\n"
	else
		printf "\n${RED}Error:${NOCOLOR} ${req} commands are missing to execute ${NAMEPROG##*/} properly!\nPlease install them on your system to use ${NAMEPROG##*/}\n\n"
	fi
	exit 1
fi

##Check the ability to work
if [[ $# -ne $ARGS ]]; then
    printf "\n${GREEN}Usage:${NOCOLOR} ${NAMEPROG##*/} target_file.gff\n\n"
    exit 1
elif [[ ! -f $DATA ]];then
	printf "\n${RED}Error:${NOCOLOR} the file '${DATA}' does not exit!\nPlease use an existing file.\n${GREEN}Usage:${NOCOLOR} ${NAMEPROG##*/} target_file.gff\n\n"
	exit 1
elif [[ $(wc -l $DATA) = "0 ${DATA}" ]]; then
	printf "\n${RED}Error:${NOCOLOR} the file is empty!\n\n"
	exit 1
fi

##Checking the presence of commented lines
COMMENTLINES=$(grep "^#" $DATA | wc -l)
if [[ $COMMENTLINES -ne 0 ]]; then
	if [[ $COMMENTLINES -eq 1 ]]; then
		printf "\n${ORANGE}WARNING:${NOCOLOR} the file present 1 commented line.\n"
	else
		printf "\n${ORANGE}WARNING:${NOCOLOR} the file present ${COMMENTLINES} commented lines.\n"
	fi
	printf "To be sure that will not interfere with ${NAMEPROG##*/}\nA new file without commented lines will be create.\n"
	NAMEFILEUNCOM=${DATA%%.*}_withoutCommentedLines.$EXTENSION
	if [[ -f $NAMEFILEUNCOM ]]; then
		while true; do
			printf "\n"
			printf "The directory already present a file (${NAMEFILEUNCOM}) sorted without commented lines.\nDo you want to overwrite it? (Y/n)\n"
			read ANSWER
			printf "\n"
			case $ANSWER in
				[yY][eE][sS]|[yY] ) 
					sed '/^#/d' $DATA > $NAMEFILEUNCOM & PID=$!								
					i=0 &
					while kill -0 $PID 2>/dev/null; do
						i=$(( (i+1) %4 ))
						printf "\rOverwrite of the the file ${NAMEFILEUNCOM} ${SPIN:$i:1}"
						sleep .1
					done
					printf "\n\n"
					DATA=${NAMEFILEUNCOM}
					break;;
				[nN][oO]|[nN] )
					printf "%s\n" "Ok, the file already present in the directory will be use for the next step." ""
					DATA=${NAMEFILEUNCOM}
					break;;				
				* ) 
					printf "\033c"
					printf "%s\n" "" "Please answer yes or no." "";;
			esac
		done
	else
		sed '/^#/d' $DATA > $NAMEFILEUNCOM & PID=$!								
		i=0 &
		while kill -0 $PID 2>/dev/null; do
			i=$(( (i+1) %4 ))
			printf "\rCreation of file without commented lines ${SPIN:$i:1}"
			sleep .1
		done
		printf "\n\n"
		DATA=${NAMEFILEUNCOM}
	fi
fi

##Check the structure of the file
head -n 1 $DATA | awk 'BEGIN{FS="\t"}{print NF}' | uniq >> .check.tmp &&
tail -n 1 $DATA | awk 'BEGIN{FS="\t"}{print NF}' | uniq >> .check.tmp & #&
##Could be long for big file...
#awk 'BEGIN{FS="\t"}{print NF}' $DATA | uniq | wc -l >> .check.tmp &
PID=$!
i=0 &
while kill -0 $PID 2>/dev/null; do
	i=$(( (i+1) %4 ))
	printf "\rChecking the ability to work with ${DATA##*/} ${SPIN:$i:1}"
	sleep .1
done
printf "\n\n"
printf "%s\n" "$FIRSTLINE" "$LASTLINE" "$NAMEFILEUNCOM"
if [[ "$(sed -n '1p' .check.tmp)" -ne 9 ]]; then
	printf "\n${RED}Error:${NOCOLOR} the first line of the file does not present 9 columns!\n\n"
	exit 1
elif [[ "$(sed -n '2p' .check.tmp)" -ne 9 ]]; then
	printf "\n${RED}Error:${NOCOLOR} the last line of the file does not present 9 columns!\n\n"
	exit 1
#elif [[ "$(sed -n '3p' .check.tmp)" -ne 1  ]]; then
#	printf "%s\n" "Error: some lines of the file does not present 9 columns!" ""
#	exit 1
fi
rm .check.tmp

##Start to work
printf "\033c"
if [[ ${DATA##*.} != $EXTENSION ]]; then
	printf "\n${ORANGE}WARNING:${NOCOLOR} The file extension sould be .${EXTENSION}\nMake sure that the file present an gff structure.\n"
fi

##Trash all tmp file if it is existe
rm -f .*.tmp

printf "%s\n" "" "Yeah, let's sort gff files..." ""
r=0
while true; do
	#Choice of the tool
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
		
		#choice
		printf "\n"
		printf "Which tool do you would like to use on ${GREEN}${DATA##*/}${NOCOLOR} ?\n"
		printf "\n"
		printf "%s\n" "=============== Tools specific to human genome sorting ===============" ""
		printf "%s\n" "1 - Classical Human Chromosomes sorter" "2 - GFF to BED file" "3 - Promoter regions extractor (in development)" ""
		printf "%s\n" "======================= Tools to sort gff file =======================" ""
		printf "%s\n" "4 - Sort by sources present in my file (column 2)" "5 - Sort by type of region present in my file (column 3)" "6 - Attributes explorer (Sort or extract: IDs, gbkey, biotype, gene list) (column 9)" "7 - Isoform inspector (in development)" ""
		printf "%s\n %s\n \r%s" "If you would like to quite, please answer 'q' or 'quite'" "" "Please enter the number of the choosen tool: "
		read ANSWER
		case $ANSWER in
			[1-7] )
				printf "\n"
				t=$ANSWER
				break;;
			[qQ]|[qQ][uU][iI][tT] )
				printf "\033c"
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

	##Tool 1: Classical Human Chromosomes sorter
	while true; do
		if [[ t -eq 1 ]]; then
			if [[ $(grep "^NC" $DATA | wc -l) -eq 0 && $(grep "^chr" $DATA | wc -l) -eq 0 ]]; then
				printf "\033c"
				printf "%s\n" "Error: the file does not contain classical human chromosome names (NC_XXXXXX or chrX)!" ""
				break
			elif [[ $(grep "^NC" $DATA | wc -l) -gt 0 && $(grep "^chr" $DATA | wc -l) -gt 0 ]]; then
				while true; do
					printf "%s\n" "Names of human chromosomes in the file are named by 2 different ways ('NC_XXXXXX' and 'chrX')" "Which name do you want to keep in the gff file to homogenize the chromosome SeqIDs? (NC or chr)" 
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
												printf "\rHomogenization of the file by 'NC' ${SPIN:$i:1}"
												sleep .1
											done
											printf "%s\n" "" "" "The file has been re-homogenize by 'NC' chromosome names." ""
											break;;
										[nN][oO]|[nN] )
											printf "%s\n" "" "Ok, the file already present in the directory will be use for the next steps." ""
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
									printf "\rHomogenization of the file by 'NC' ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "The file has been homogenize by 'NC' chromosome names." ""
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
												printf "\rHomogenization of the file by 'chr' ${SPIN:$i:1}"
												sleep .1
											done		
											printf "%s\n" "" "" "The file has been re-homogenize by 'chr' chromosome names." ""
											break;;
										[nN][oO]|[nN] )
											printf "%s\n" "" "Ok, the file already present in the directory will be use for the next steps." ""
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
									printf "\rHomogenization of the file by 'chr' ${SPIN:$i:1}"
									sleep .1
								done
								printf "%s\n" "" "" "The file has been homogenize by 'chr' chromosome names." ""
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
							printf "\033c"
							printf "%s\n" "" "The file has been re-sorted by the main human chromosomes." ""
							break;;
						[nN][oO]|[nN] )
							printf "%s\n" "" "Ok, the file already present in the directory has not been overwritten." ""
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
				printf "\033c"
				printf "%s\n" "" "" "The file has been sorted by the main human chromosomes." ""
			fi
			((r++))
			while true; do
				printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the new sorted file? (Y/n)" 
				read ANSWER
				printf "\n"
				case $ANSWER in
					[yY]|[yY][eE][sS] )
						DATA=${NAMEFILE2}
						break;;
					[nN]|[nN][oO] )
						DATA=${DATA}
						break;;
					* )
						printf "\033c"
						printf "%s\n" "" "Please answer yes or no." ""
						;;
				esac
			done
		break
		else
			break
		fi
	done

	##Tool 2: GFF to BED file
	while true; do
		if [[ t -eq 2 ]]; then
			while true; do
				printf "\033c"
				printf "%s\n" "Which can of BED to you want to create with '${DATA##*/}'? (bed3 - bed6 - both)"
				read ANSWER
				case $ANSWER in
					[bB][eE][dD][3] )
						NAMEBED3="${DATA%%.*}.bed3"
						if [[ -f $NAMEBED3 ]]; then
							while true; do
								printf "%s\n" "The directory already present a BED3 file (${NAMEBED3##*/})." "Do you want to overwrite this file? (Y/n)"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY] ) 
									awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $DATA> $NAMEBED3
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
									printf "\033c"
									printf "%s\n" "${NAMEBED3##*/} file has been overwritten." ""
									break;;
									[nN][oO]|[nN] )
									printf "\033c"
									printf "Ok, ${NAMEBED3##*/} file present in the directory has not been overwritten.\n"
									break;;
									* ) 
									printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $DATA > $NAMEBED3
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
							printf "\033c"
							printf "%s\n" "${NAMEBED3##*/}file has been generated." ""
						fi
						break;;
					[bB][eE][dD][6] )
						NAMEBED6="${DATA%%.*}.bed6"
						if [[ -f $NAMEBED6 ]]; then
							while true; do
								printf "%s\n" "The directory already present a BED6 file (${NAMEBED6##*/})." "Do you want to overwrite this file? (Y/n)"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY] )
									awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $DATA > $NAMEBED6
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
									printf "\033c"
									printf "%s\n" "${NAMEBED6##*/} file has been overwritten." ""
									break;;
									[nN][oO]|[nN] )
									printf "\033c"
									printf "Ok, ${NAMEBED6##*/} file present in the directory has not been overwritten.\n"
									break;;				
	   								* ) 
									printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $DATA > $NAMEBED6
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
							printf "\033c"
							printf "%s\n" "${NAMEBED6##*/} file has been generated." ""
						fi
						break;;
					[bB][oO][tT][hH] )
						NAMEBED3="${DATA%%.*}.bed3"
						NAMEBED6="${DATA%%.*}.bed6"
						if [[ -f $NAMEBED3 ]]; then
							while true; do
								printf "%s\n" "The directory already present a BED3 file (${NAMEBED3##*/})." "Do you want to overwrite this file? (Y/n)"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY] ) 
									awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $DATA> $NAMEBED3
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
									printf "\033c"
									printf "%s\n" "${NAMEBED3##*/} file has been overwritten." ""
									break;;
									[nN][oO]|[nN] )
									printf "\033c"
									printf "Ok, ${NAMEBED3##*/} file present in the directory has not been overwritten.\n"
									break;;
									* ) 
									printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $DATA > $NAMEBED3
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
							printf "\033c"
							printf "%s\n" "${NAMEBED3DATA##*/} file has been generated." ""
						fi
						if [[ -f $NAMEBED6 ]]; then
							while true; do
								printf "%s\n" "The directory already present a BED6 file (${NAMEBED6##*/})." "Do you want to overwrite this file? (Y/n)"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY] )
									awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $DATA > $NAMEBED6
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
									printf "\033c"
									printf "%s\n" "${NAMEBED6##*/} file has been overwritten." ""
									break;;
									[nN][oO]|[nN] )
									printf "\033c"
									printf "Ok, ${NAMEBED6##*/} file present in the directory has not been overwritten.\n"
									break;;				
	   								* ) 
									printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $DATA > $NAMEBED6
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
							printf "\033c"
							printf "%s\n" "${NAMEBED6##*/} file has been generated." ""
						fi
						break;;		
   					* ) 
						printf "%s\n" "" "Please answer bed3, bed6 or both." "";;
				esac
			done
			((r++))
			break
		else
			break
		fi
	done


	##Tool 3: Promoter regions extractor (in development)
	while true; do
		if [[ t -eq 3 ]]; then
			printf
			((r++))
			while true; do
				printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the new sorted file? (Y/n)" 
				read ANSWER
				printf "\n"
				case $ANSWER in
					[yY]|[yY][eE][sS] )
						DATA=${NAMEFILE}
						break;;
					[nN]|[nN][oO] )
						DATA=${DATA}
						break;;
					* )
						printf "\033c"
						printf "%s\n" "" "Please answer yes or no." ""
						;;
				esac
			done
			break
		else
			break
		fi
	done

	##Tool 4: Sort by sources
	while true; do
		if [[ t -eq 4 ]]; then
			printf "\033c"
			printf "%s\n" "" "" "This are sources present in the file:" "" "Number_of_line	Source" "$(awk 'BEGIN{FS="\t"}{print$2}' $DATA | sort | uniq -c)" "" &
			awk 'BEGIN{FS="\t";OFS="\t"}{print$2}' $DATA | sort | uniq | sed 's/ /_/g' > .sources.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for sources present in the file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $(awk '/^$/ {x += 1};END {print x }' .sources.tmp) -ge 1 ]]; then
				printf "\n${ORANGE}WARNING:${NOCOLOR} 1 of the source does not present character!\nIf you want to sort this source please enter 'without_character'\n\n"
			fi
			if [[ $(wc -l .sources.tmp) = "1 .sources.tmp" ]]; then
				printf "\033c"
				printf "%s\n" "Only 1 source has been found in the file." "You do not need to sort the file by the database source." ""
				if [[ $(awk '/^$/ {x += 1};END {print x }' .sources.tmp) -ge 1 ]]; then
					printf "${ORANGE}WARNING:${NOCOLOR} the only source of the file does not present character!\n"
				fi
				break
			else
				NUMOFSOURCES=$(cat .sources.tmp | wc -l)
				for (( i = 1; i < ${NUMOFSOURCES} + 1; i++ )); do
					eval LISTSOURCES[$i-1]="$(sed -n $i'p' .sources.tmp)"
				done
			fi
			rm .sources.tmp
			while true; do
				printf "By which source do you want to sort? (If the source name present space ' ', please use '_' instead)\n"
				read ANSWER 
				sourcewithoutcharacter=0
				if [[ "$ANSWER" == "without_character" ]]; then
					sourcewithoutcharacter=1	
					SOURCETOSORT="sourceWithoutCharacter"			
				else
					for (( i = 0; i < ${NUMOFSOURCES}; i++ )); do
						if [[ $ANSWER = ${LISTSOURCES[$i]} ]]; then
							SOURCETOSORT=${LISTSOURCES[$i]}
						fi
					done
				fi
				if [[ ! -z $SOURCETOSORT ]]; then
					if [[ $sourcewithoutcharacter -eq 1 ]]; then
						SOURCETOSORT2=""
					else
						printf $SOURCETOSORT > .sourcetosort.tmp				
						SOURCETOSORT2="$(sed 's/_/ /g' .sourcetosort.tmp)"
						rm .sourcetosort.tmp
					fi
					NAMEFILE=${DATA%%.*}_${SOURCETOSORT}SourceSorted.$EXTENSION
					if [[ -f $NAMEFILE ]]; then
					while true; do
						printf "\nThe directory already present a file ("$NAMEFILE") sorted by ${SOURCETOSORT2}\nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY] ) 
								awk 'BEGIN{FS="\t"; OFS="\t"}{ if ($2=="'"$SOURCETOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rSorting by ${SOURCETOSORT2} in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "\033c"
								if [[ $sourcewithoutcharacter -eq 1 ]]; then
									printf "\nThe file has been re-sorted by the source without character.\n\n"
								else
									printf "\nThe file has been re-sorted by the source: ${SOURCETOSORT2}\n\n"
								fi
								break;;
							[nN][oO]|[nN] )
								printf "Ok, the file already present in the directory will be use for the next steps.\n"
								break;;				
		   					* ) 
								printf "%s\n" "" "Please answer yes or no." "";;
						esac
					done
					else
						awk 'BEGIN{FS="\t"; OFS="\t"}{ if ($2=="'"$SOURCETOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rSorting by ${SOURCETOSORT2} in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\033c"
						if [[ $sourcewithoutcharacter -eq 1 ]]; then
							printf "\nThe file has been sorted by the source without character.\n\n"
						else
							printf "\nThe file has been sorted by the source: ${SOURCETOSORT2}\n\n"
						fi
					fi
					break
				else
					printf "%s\n" "" "The source that you wrote is not find in the file." ""
				fi
			done
			((r++))
			while true; do
				printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the new sorted file? (Y/n)" 
				read ANSWER
				printf "\n"
				case $ANSWER in
					[yY]|[yY][eE][sS] )
						DATA=${NAMEFILE}
						break;;
					[nN]|[nN][oO] )
						DATA=${DATA}
						break;;
					* )
						printf "\033c"
						printf "%s\n" "" "Please answer yes or no." ""
						;;
				esac
			done
			break
		else
			break
		fi
	done

	#Tool 5 : Sort by type of region
	while true; do
		if [[ t -eq 5 ]]; then
			printf "\033c"
			printf "%s\n" "" "" "This are regions present in the file:" "" "Number_of_line	Region" "$(awk 'BEGIN{FS="\t"}{print$3}' $DATA | sort | uniq -c)" "" &
			awk 'BEGIN{FS="\t";OFS="\t"}{print$3}' $DATA  | sort | uniq | sed 's/ /_/g' > .regions.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for region features present in the file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $(awk '/^$/ {x += 1};END {print x }' .regions.tmp) -ge 1 ]]; then
				printf "\n${ORANGE}WARNING:${NOCOLOR} 1 of the region does not present character!\nIf you want to sort this region please enter 'without_character'\n\n"
			fi
			if [[ $(wc -l .regions.tmp) = "1 .regions.tmp" ]]; then
				printf "\033c"
				printf "%s\n" "Only 1 region has been found in the file." "You do not need to sort the file by region." ""
				if [[ $(awk '/^$/ {x += 1};END {print x }' .regions.tmp) -ge 1 ]]; then
					printf "${ORANGE}WARNING:${NOCOLOR} the only region of the file does not present character!\n"
				fi
				break
			else
				NUMOFREGIONS=$(cat .regions.tmp | wc -l)
				for (( i = 1; i < ${NUMOFREGIONS} + 1; i++ )); do
					eval LISTREGIONS[$i-1]="$(sed -n $i'p' .regions.tmp)"
				done
			fi
			rm .regions.tmp
			while true; do
				printf "By which region do you want to sort? (If the region name present space ' ', please use '_' instead)\n"
				read ANSWER
				printf "\n"
				regonwithoutcharacter=0
				if [[ "$ANSWER" == "without_character" ]]; then
					regonwithoutcharacter=1	
					REGIONTOSORT="regionWithoutCharacter"
				else
					for (( i = 0; i < ${NUMOFREGIONS}; i++ )); do
						if [[ $ANSWER = ${LISTREGIONS[$i]} ]]; then
							REGIONTOSORT=${LISTREGIONS[$i]}
						fi
					done
				fi
				if [[ ! -z $REGIONTOSORT ]]; then
					if [[ $regonwithoutcharacter -eq 1 ]]; then
						REGIONTOSORT2=""
					else
						printf $REGIONTOSORT > .regiontosort.tmp
						REGIONTOSORT2="$(sed 's/_/ /g' .regiontosort.tmp)"
						rm .regiontosort.tmp
					fi
					NAMEFILE=${DATA%%.*}_${REGIONTOSORT}RegionSorted.$EXTENSION
					if [[ -f $NAMEFILE ]]; then
					while true; do
						printf "\nThe directory already present a file ("$NAMEFILE") sorted by ${REGIONTOSORT2}.\nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY] ) 
							awk 'BEGIN{FS="\t";OFS="\t"}{ if ($3=="'"$REGIONTOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by ${REGIONTOSORT2} in process ${SPIN:$i:1}"
								sleep .1
							done
							printf "\033c"
							if [[ $regonwithoutcharacter -eq 1 ]]; then
								printf "\nThe file has been re-sorted by the region without character.\n\n"
							else
								printf "\nThe file has been re-sorted by the region: ${REGIONTOSORT2}\n\n"
							fi
							break;;
							[nN][oO]|[nN] )
							printf "Ok, the file already present in the directory will be use for the next steps.\n"
							break;;				
	       					* ) 
							printf "%s\n" "" "Please answer yes or no." "";;
	    				esac
					done
					else
						awk 'BEGIN{FS="\t";OFS="\t"}{ if ($3=="'"$REGIONTOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rSorting by ${REGIONTOSORT2} in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\033c"
						if [[ $regonwithoutcharacter -eq 1 ]]; then
							printf "\nThe file has been sorted by the region without character.\n\n"
						else
							printf "\nThe file has been sorted by the region: ${REGIONTOSORT2}\n\n" 
						fi
					fi
	        		break
				else
					printf "%s\n" "" "The region that you wrote is not find in the file." ""
				fi
			done
			((r++))
			while true; do
				printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the new sorted file? (Y/n)" 
				read ANSWER
				printf "\n"
				case $ANSWER in
					[yY]|[yY][eE][sS] )
						DATA=${NAMEFILE}
						break;;
					[nN]|[nN][oO] )
						DATA=${DATA}
						break;;
					* )
						printf "\033c"
						printf "%s\n" "" "Please answer yes or no." ""
						;;
				esac
			done
			break
		else
			break
		fi
	done

	#Tool 6: Sort or extract list from attributes
	while true; do
		if [[ t -eq 6 ]]; then
			printf "\033c"
			printf "${ORANGE}WARNING:${NOCOLOR} the file sould have a gff3 structure of attributes (column 9): XX=XX1;XX=XX;etc...\n\n"
			cut -f9 $DATA | sed 's/\;/\t/g' > .attributes0.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rExtracting attributes present in the file ${SPIN:$i:1}"
				sleep .1
			done
			printf "\n\n"
			MAXNUMCOL=$(awk 'BEGIN{FS="\t"}{print NF}' .attributes0.tmp | sort -n | sed -n '$p')
			printf "${MAXNUMCOL} attributes max per line have been found in the file\n\n"
			for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
				awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); print subfield[1]}' .attributes0.tmp >> .attributes1.tmp
				printf "\rRecovering of the attribute n°${i}"
			done

			# boucle lente.. car copie des lignes vides lorsque la colonne n'existe pas... (récup nombre colonne exacte par ligne puis récupe des attribute spe plus encore + lent! mais pas besoin de sed apres)
			printf "\n"
			sed -i '/^$/d' .attributes1.tmp
			sort .attributes1.tmp | uniq -c > .numattributes.tmp &
			sort .attributes1.tmp | uniq > .attributes2.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rChecking the number of attributes in the file ${SPIN:$i:1}"
				sleep .1
			done
			rm .attributes1.tmp
			while true; do
				while true; do
					e=0
					printf "%s\n" "" "" "This are attributes present in the file:" "" "Number	Attribute" "$(cat .numattributes.tmp)" ""
					printf "Do you want to extract the list of content from 1 attribute or do you want to sort by one of them? (E/s)\n"
					read ANSWER
					printf "\n"
					case $ANSWER in
						[eE]|[eE][xX][tT][rR][aA][cC][tT] )
							while true; do
								printf "\033c"
								printf "%s\n" "This are attributes present in the file:" "" "Number	Attribute" "$(cat .numattributes.tmp)" ""
								NUMOFATTRIBUTE=$(cat .attributes2.tmp | wc -l)
								for (( i = 1; i < ${NUMOFATTRIBUTE} + 1; i++ )); do
									eval LISTATTRIBUTE[$i-1]="$(sed -n $i'p' .attributes2.tmp)"
								done
								printf "Which attribute do you want to extract?\n"
								read ANSWER
								for (( i = 0; i < ${NUMOFATTRIBUTE}; i++ )); do
									if [[ $ANSWER = ${LISTATTRIBUTE[$i]} ]]; then
										ATTOEXTRACT=${LISTATTRIBUTE[$i]}
									fi
								done
								if [[ ! -z $ATTOEXTRACT ]]; then
									NAMEFILE1=${DATA%%.*}_${ATTOEXTRACT}List.txt
									if [[ -f $NAMEFILE1 ]]; then
										while true; do
											printf "\nThe directory already present the file ${NAMEFILE1}.\nDo you want to overwrite it? (Y/n)\n"
											read ANSWER
											printf "\n"
											case $ANSWER in
												[yY][eE][sS]|[yY] ) 
													for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
														grep $ATTOEXTRACT .attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOEXTRACT}'") print subfield[2]}' >> $NAMEFILE1
													done
													printf "\nThe list of all content of the attribute '${ATTOEXTRACT}' has been overwritten.\n"
													break;;
												[nN][oO]|[nN] )
													printf "Ok, the file already present in the directory will be use for the next steps.\n"
													break;;				
						       					* ) 
													printf "%s\n" "" "Please answer yes or no." "";;
						    				esac
										done
									else
										for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
											grep $ATTOEXTRACT .attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOEXTRACT}'") print subfield[2]}' >> $NAMEFILE1
										done
										printf "\nThe list of all content of the attribute '${ATTOEXTRACT}' has been created.\n"
									fi
									while true; do
										printf "%s\n" "" "Do you to extract unique occurence of the list? (Y/n)" 
										read ANSWER
										printf "\n"
										case $ANSWER in
											[yY]|[yY][eE][sS] )
												NAMEFILE2=${NAMEFILE1%%.*}_unique.txt
												if [[ $(uniq $NAMEFILE1 | wc -l) -eq $(cat $NAMEFILE1 | wc -l) ]]; then
													printf "All the attribute '${ATTOEXTRACT}' are already unique in the file\n"
													mv $NAMEFILE1 $NAMEFILE2
													break
												fi												
												if [[ -f $NAMEFILE2 ]]; then
													while true; do
														printf "\nThe directory already present the file ${NAMEFILE2}.\nDo you want to overwrite it? (Y/n)\n"
														read ANSWER
														printf "\n"
														case $ANSWER in
															[yY][eE][sS]|[yY] ) 
																uniq $NAMEFILE1 > $NAMEFILE2
																printf "\nThe list of unique content of the attribute '${ATTOEXTRACT}' has been overwritten.\n"
																break;;
															[nN][oO]|[nN] )
																printf "Ok, the file already present in the directory will be use for the next steps.\n"
																break;;				
									       					* ) 
																printf "%s\n" "" "Please answer yes or no." "";;
									    				esac
													done
												else
													uniq $NAMEFILE1 > $NAMEFILE2
													printf "\nThe list of unique content of the attribute '${ATTOEXTRACT}' has been created.\n"
												fi
												break;;
											[nN]|[nN][oO] )
												break;;
											* )
												printf "\033c"
												printf "%s\n" "" "Please answer yes or no."
												;;
										esac
									done
									while true; do
										printf "%s\n" "" "Do you to extract list from an other attribute? (Y/n)" 
										read ANSWER
										printf "\n"
										case $ANSWER in
											[yY]|[yY][eE][sS] )
												break;;
											[nN]|[nN][oO] )
												e=1
												break;;
											* )
												printf "\033c"
												printf "%s\n" "" "Please answer yes or no." ""
												;;
										esac
									done
								else
									printf "%s\n" "" "The attribute that you wrote is not find in the file." ""
								fi
								if [[ $e -eq 1 ]]; then
									break
								fi
							done
							;;
						[sS]|[sS][oO][rR][tT] )
							while true; do
								printf "\033c"
								printf "%s\n" "This are attributes present in the file:" "" "Number	Attribute" "$(cat .numattributes.tmp)" ""
								NUMOFATTRIBUTE=$(cat .attributes2.tmp | wc -l)
								for (( i = 1; i < ${NUMOFATTRIBUTE} + 1; i++ )); do
									eval LISTATTRIBUTE[$i-1]="$(sed -n $i'p' .attributes2.tmp)"
								done
								printf "Which attribute do you want to sort?\n"
								read ANSWER
								for (( i = 0; i < ${NUMOFATTRIBUTE}; i++ )); do
									if [[ $ANSWER = ${LISTATTRIBUTE[$i]} ]]; then
										ATTOSORT=${LISTATTRIBUTE[$i]}
									fi
								done
								if [[ ! -z $ATTOSORT ]]; then
									if [[ $(grep "${ATTOSORT}=" .attributes0.tmp | wc -l) -eq $(cat .attributes0.tmp | wc -l ) ]]; then
										printf "\nThe choosen attribute is present on all line of the file!\n"
										while true; do
											printf "%s\n" "" "Do you to explore the content of '${ATTOSORT}'? (Y/n)" 
											read ANSWER
											printf "\n"
											case $ANSWER in
												[yY]|[yY][eE][sS] )
													for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
														grep ${ATTOSORT} .attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOSORT}'") print subfield[2]}' >> .${ATTOSORT}.tmp
													done
													if [[ $(cat .${ATTOSORT}.tmp | uniq | wc -l) -eq $(cat .attributes0.tmp | wc -l) ]]; then
														printf "\033c"
														printf "All content of '${ATTOSORT}' seem to be unique \nUse the attribute extraction to obtain the list of the content of '${ATTOSORT}'."
														
														#Ajout la fonction récupe des noms comme id=idXX

													elif [[ $(cat .${ATTOSORT}.tmp | uniq | wc -l) -eq 1 ]]; then
														printf "\033c"
														printf "Only 1 type of sub-attribute of '${ATTOSORT}' has been found in the file!\n"
														UNIQLINE="$(sed -n '1p' .${ATTOSORT}.tmp)"
														NAMEFILE3=${DATA%%.*}_${ATTOSORT}Attributes_${UNIQLINE}Uniq.${EXTENSION}
														cp $DATA $NAMEFILE3
														printf "A copy of the file has been created with the name: ${NAMEFILE3}"
													else														
														while true; do
															printf "%s\n" "This are unique content of '${ATTOSORT}' present in the file:" "" "Number	type_of_${ATTOSORT}" "$(sort .${ATTOSORT}.tmp | uniq -c)" ""
															sort .${ATTOSORT}.tmp | uniq > .${ATTOSORT}uniq.tmp
															NUMOFSUBATTRIBUTE=$(cat .${ATTOSORT}uniq.tmp | uniq | wc -l)
															for (( i = 1; i < ${NUMOFSUBATTRIBUTE} + 1; i++ )); do
																eval LISTSUBATTRIBUTE[$i-1]="$(sed -n $i'p' .${ATTOSORT}uniq.tmp)"
															done
															printf "By which sub-attribute of '${ATTOSORT}' do you want to sort?\n"
															read ANSWER
															printf "\n"
															for (( i = 0; i < ${NUMOFSUBATTRIBUTE}; i++ )); do
																if [[ $ANSWER = ${LISTSUBATTRIBUTE[$i]} ]]; then
																	SUBATTOSORT=${LISTSUBATTRIBUTE[$i]}
																fi
															done
															if [[ ! -z $SUBATTOSORT ]]; then
																NAMEFILE3=${DATA%%.*}_${ATTOSORT}Attributes_${SUBATTOSORT}Sorted.${EXTENSION}										
																if [[ -f $NAMEFILE3 ]]; then
																	while true; do
																		printf "\nThe directory already present a file (${NAMEFILE3}) sorted by the sub-attribute '${SUBATTOSORT}'.\nDo you want to sort again? (Y/n)\n"
																		read ANSWER
																		printf "\n"
																		case $ANSWER in
																			[yY][eE][sS]|[yY] )																			
																			grep "${ATTOSORT}=${SUBATTOSORT}" $DATA > $NAMEFILE3 & PID=$!
																			i=0 &
																			while kill -0 $PID 2>/dev/null; do
																				i=$(( (i+1) %4 ))
																				printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
																				sleep .1
																			done
																			printf "\033c"
																			printf "\nThe file has been re-sorted by the sub-attribute: ${SUBATTOSORT}\n\n"
																			break;;
																			[nN][oO]|[nN] )
																			printf "Ok, the file already present in the directory will has not been overwritten.\n"
																			break;;				
													       					* ) 
																			printf "%s\n" "" "Please answer yes or no." "";;
													    				esac
																	done
																else
																	grep "${ATTOSORT}=${SUBATTOSORT}" $DATA > $NAMEFILE3 & PID=$!
																	i=0 &
																	while kill -0 $PID 2>/dev/null; do
																		i=$(( (i+1) %4 ))
																		printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
																		sleep .1
																	done
																	printf "\033c"
																	printf "\nThe file has been sorted by the sub-attribute: ${SUBATTOSORT}\n\n"																	
																fi
																break														
															else
																printf "\033c"
																printf "%s\n" "" "The sub-attribute that you wrote is not find in the file." ""
															fi
														done
														rm .${ATTOSORT}uniq.tmp
													fi													
													rm .${ATTOSORT}.tmp													
													s=1
													break
													;;
												[nN]|[nN][oO] )	
													e=1											
													break;;
												* )
													printf "\033c"
													printf "%s\n" "" "Please answer yes or no." ""
													;;
											esac
										done									
									else
										NAMEFILE3=${DATA%%.*}_${ATTOSORT}AttributesSorted.${EXTENSION}										
										if [[ -f $NAMEFILE3 ]]; then
											while true; do
												printf "\nThe directory already present a file (${NAMEFILE3}) sorted by ${ATTOSORT}.\nDo you want to sort again? (Y/n)\n"
												read ANSWER
												printf "\n"
												case $ANSWER in
													[yY][eE][sS]|[yY] ) 
													grep "${ATTOSORT}=" $DATA > $NAMEFILE3 & PID=$!
													i=0 &
													while kill -0 $PID 2>/dev/null; do
														i=$(( (i+1) %4 ))
														printf "\rSorting by ${ATTOSORT} in process ${SPIN:$i:1}"
														sleep .1
													done
													printf "\033c"
													printf "\nThe file has been re-sorted by the attribute: ${ATTOSORT}\n\n"
													break;;
													[nN][oO]|[nN] )
													printf "Ok, the file already present in the directory will has not been overwritten.\n"
													break;;				
							       					* ) 
													printf "%s\n" "" "Please answer yes or no." "";;
							    				esac
											done
										else
											grep "${ATTOSORT}=" $DATA > $NAMEFILE3 & PID=$!
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rSorting by ${ATTOSORT} in process ${SPIN:$i:1}"
												sleep .1
											done
											printf "\033c"
											printf "\nThe file has been sorted by the attribute: ${ATTOSORT}\n\n"
										fi
										s=1
									fi
									break
								else
									printf "\033c"
									printf "%s\n" "" "The attribute that you wrote is not find in the file." ""
								fi								
							done
							;;
						* )
							printf "\033c"
							printf "%s\n" "" "Please answer extract or sort." ""
							;;
					esac
					if [[ $e -eq 1 ]]; then
						break
					fi
				done
				while true; do
					printf "%s\n" "" "Do you to extract list or sort from an other attribute? (Y/n)" 
					read ANSWER
					printf "\n"
					case $ANSWER in
						[yY]|[yY][eE][sS] )
							printf "\033c"
							break
							;;
						[nN]|[nN][oO] )
							e=2
							break;;
						* )
							printf "\033c"
							printf "%s\n" "" "Please answer yes or no." ""
							;;
					esac
				done
				if [[ $e -eq 2 ]]; then
					break
				fi
			done
			rm .attributes2.tmp
			rm .numattributes.tmp
			rm .attributes0.tmp
			((r++))
			if [[ $s -eq 1 ]]; then
				while true; do
					printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the last sorted file? (Y/n)" 
					read ANSWER
					printf "\n"
					case $ANSWER in
						[yY]|[yY][eE][sS] )
							DATA=${NAMEFILE3}
							break;;
						[nN]|[nN][oO] )
							DATA=${DATA}
							break;;
						* )
							printf "\033c"
							printf "%s\n" "" "Please answer yes or no." ""
							;;
					esac
				done
			fi
			break
		else
			break
		fi
	done

	#Tool 7: Isoform inspector
	while true; do
		if [[ t -eq 7 ]]; then
			printf
			((r++))
			DATA=${NAMEFILE}
			break
		else
			break
		fi
	done
done
