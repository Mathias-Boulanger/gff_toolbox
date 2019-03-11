#!/bin/bash
#Made by Mathias Boulanger - 2019/03/06
#gff_tools_box.sh
#version 1.0
#use on gff file structure

ARGS=1				#The script need 1 argument
NAMEPROG=$0			#Name of the program
DATA=$1				#File in argument
EXTENSION="gff"		#Extension file necessary to run this script
SPIN='-\|/'			#Waiting characters
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[0;33m'
NOCOLOR='\033[0m'

##Resize the windows
printf '\033[8;40;175t'

##Checking needed commands
printf "Checking for needed commands\n\n"
needed_commands="awk sed grep head tail uniq wc rm sleep read kill seq cp mv" ;
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
				[yY][eE][sS]|[yY]|"" ) 
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
					printf "%s\n" "The file already present in the directory will be use for the next step." ""
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

##Trash all tmp file if it is exist
rm -f /tmp/${NAMEPROG##*/}_*.tmp

##Check the structure of the file
head -n 1 $DATA | awk 'BEGIN{FS="\t"}{print NF}' | uniq >> /tmp/${NAMEPROG##*/}_check.tmp &&
tail -n 1 $DATA | awk 'BEGIN{FS="\t"}{print NF}' | uniq >> /tmp/${NAMEPROG##*/}_check.tmp & #&
#Could be long for big file...
#awk 'BEGIN{FS="\t"}{print NF}' $DATA | uniq | wc -l >> /tmp/${NAMEPROG##*/}_check.tmp &
PID=$!
i=0 &
while kill -0 $PID 2>/dev/null; do
	i=$(( (i+1) %4 ))
	printf "\rChecking the ability to work with ${DATA##*/} ${SPIN:$i:1}"
	sleep .1
done
printf "\n\n"
printf "%s\n" "$FIRSTLINE" "$LASTLINE" "$NAMEFILEUNCOM"
if [[ "$(sed -n '1p' /tmp/${NAMEPROG##*/}_check.tmp)" -ne 9 ]]; then
	printf "\n${RED}Error:${NOCOLOR} the first line of the file does not present 9 columns!\n\n"
	rm /tmp/${NAMEPROG##*/}_check.tmp
	exit 1
elif [[ "$(sed -n '2p' /tmp/${NAMEPROG##*/}_check.tmp)" -ne 9 ]]; then
	printf "\n${RED}Error:${NOCOLOR} the last line of the file does not present 9 columns!\n\n"
	rm /tmp/${NAMEPROG##*/}_check.tmp
	exit 1
#elif [[ "$(sed -n '3p' /tmp/${NAMEPROG##*/}_check.tmp)" -ne 1  ]]; then
#	printf "%s\n" "Error: some lines of the file does not present 9 columns!" ""
#	rm /tmp/${NAMEPROG##*/}_check.tmp
#	exit 1
fi
rm /tmp/${NAMEPROG##*/}_check.tmp

##Start to work
printf "\033c"
if [[ ${DATA##*.} != $EXTENSION ]]; then
	printf "\n${ORANGE}WARNING:${NOCOLOR} The file extension should be .${EXTENSION}\nMake sure that the file present an gff structure.\n"
fi

printf "%s\n" "" "Yeah, let's play with gff files..." ""
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
		printf "%s\n" "" "Classical gff3 file should present the structure as follow:" ""
		printf "$HEADER" "SeqID" "Source" "Feature (type)" "Start" "End" "Score" "Strand" "Frame (Phase)" "Attributes"
		printf "%$width.${width}s\n" "$divider"
		printf "$STRUCTURE" \
		"NC_XXXXXX.X" "RefSeq" "gene" "1" "1728" "." "+" "." "ID=geneX;...;gbkey=Gene;gene=XXX;gene_biotype=coding_protein;..." \
		"chrX" "." "exon" "1235" "1298" "." "-" "." "ID=idX;...;gbkey=misc_RNA;gene=XXX;...;..." \
		"NC_XXXXXX.X" "BestRefSeq" "CDS" "50" "7500" "." "+" "1" "ID=idX;...;gbkey=CDS;gene=XXX;...;..."
		printf "%s\n" "" "If you would like more informations on gff file structure visit this web site: http://gmod.org/wiki/GFF3" ""
		
		#choice
		printf "\n"
		printf "Which tool do you would like to use on ${GREEN}${DATA##*/}${NOCOLOR} ?\n"
		printf "\n"
		printf "%s\n" "=================================== Tools to extract information from gff file ===================================" ""
		printf "%s\n" "1 - Classical Human Chromosomes filter (specific to human genome)" "2 - Promoter regions extractor (specific to gene regions)" "3 - Extract lines with specific sources present in my file (column 2)" "4 - Extract lines with specific type of region present in my file (column 3)" "5 - Attributes explorer (Extract list or lines with specific attribute: IDs, gbkey, biotype, gene list) (column 9)" "6 - Sequence extender (Add an interval to the start and the end of all sequences)" ""
		printf "%s\n" "=========================================== Tool to transform gff file ===========================================" ""
		printf "%s\n" "7 - GFF to BED file" "" ""
		printf "%s\n %s\n \r%s" "If you would like to quit, please answer 'q' or 'quit'" "" "Please, enter the number of the chosen tool: "
		


		read ANSWER
		case $ANSWER in
			[1-7] )
				printf "\n"
				t=$ANSWER
				break;;
			[qQ]|[qQ][uU][iI][tT] )
				printf "\033c"
				printf "%s\n" "" "Thank you to use gff tool box!"
				rm -f /tmp/${NAMEPROG##*/}_*.tmp
				if [[ $r -ne 0 ]]; then
					printf "%s\n" "" "All files generated by ${NAMEPROG##*/} have been generated in this current directory."				
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

	question_end () {
	while true; do
		printf "%s\n" "Do you want to continue to use ${NAMEPROG##*/} with the new generated file? (Y/n)" 
		read ANSWER
		printf "\n"
		case $ANSWER in
			[yY]|[yY][eE][sS]|"" )
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
	}

	##Tool 1: Classical Human Chromosomes Filter
	while true; do
		if [[ t -eq 1 ]]; then
			printf "\033c"
			printf "${NAMEPROG##*/} consider only main human chromosomes chr1 to chr22, chrX, chrY and chrM named as follow: NC_XXXXXX.X or chrX\n"
			NCDATA=$(grep "^NC" $DATA | wc -l)
			CHRDATA=$(grep "^chr" $DATA | wc -l)
			if [[ $NCDATA -eq 0 && $CHRDATA -eq 0 ]]; then
				printf "\033c"
				printf "\n${RED}Error:${NOCOLOR} the file does not contain classical human chromosome names (NC_XXXXXX.X or chrX)!\n"
				break
			elif [[ $NCDATA -gt 0 && $CHRDATA -gt 0 ]]; then
				while true; do
					printf "%s\n" "Human chromosome names in the file are named by 2 different ways ('NC_XXXXXX.X' and 'chrX')" "Which name do you want to keep in the gff file to homogenize the chromosome SeqIDs? (NC or chr)" 
					read ANSWER
					printf "\n"
					CHRNAMES=( "chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY" "chrM" )
					x=1
					e=0		
					case $ANSWER in
						[nN][cC] )
							SORTCHR="^NC"
							NAMEFILE1=${DATA%%.*}_formatNC.$EXTENSION
							NCNAMES=( "NC_000001" "NC_000002" "NC_000003" "NC_000004" "NC_000005" "NC_000006" "NC_000007" "NC_000008" "NC_000009" "NC_000010" "NC_000011" "NC_000012" "NC_000013" "NC_000014" "NC_000015" "NC_000016" "NC_000017" "NC_000018" "NC_000019" "NC_000020" "NC_000021" "NC_000022" "NC_000023" "NC_000024" "NC_012920" )
							cut -f1 $DATA | grep "^NC" | sort | uniq > /tmp/${NAMEPROG##*/}_NC_names.tmp
							NUMNCNAMES=$(uniq /tmp/${NAMEPROG##*/}_NC_names.tmp | wc -l)
							for (( i = 0; i < ${NUMNCNAMES}+1; i++ )); do
								if [[ $(sed -n $i'p' /tmp/${NAMEPROG##*/}_NC_names.tmp | awk '{split($1, subfield, "."); print subfield[1]}' | wc -c) -ne 10 ]]; then
									sed -i -e $i'd' /tmp/${NAMEPROG##*/}_NC_names.tmp
								fi
							done
							if [[ $NUMNCNAMES -gt 25 ]]; then
								printf "\n${RED}Error:${NOCOLOR} More than 25 classical human chromosome names (NC_XXXXXX.X) are detected!\nPlease check the SeqIDs content of the file\nThis are NC names found in the file :" "" "$(cat /tmp/${NAMEPROG##*/}_NC_names.tmp)" ""
								e=1
								break
							elif [[ $(awk '{split($1, subfield, "."); print subfield[1]}' /tmp/${NAMEPROG##*/}_NC_names.tmp | uniq | wc -l) -ne $(awk '{split($1, subfield, "."); print subfield[1]}' /tmp/${NAMEPROG##*/}_NC_names.tmp | wc -l) ]]; then
								printf "%s\n" "${RED}Error:${NOCOLOR} One of your NC name present different versions! (ex: NC_000001.1 and NC_000001.2)" "Please check the SeqIDs content of the file" "This are NC names found in the file :" "" "$(cat /tmp/${NAMEPROG##*/}_NC_names.tmp)" ""
								e=1
								break
							else
								if [[ $NUMNCNAMES -lt 25 ]]; then
									N=$(( 25 - ${NUMNCNAMES} ))
									for (( i = 1; i < ${N}; i++ )); do
										printf "\n" >> /tmp/${NAMEPROG##*/}_NC_names.tmp
									done
								fi
								for (( i = 0; i < 26; i++ )); do
									if [[ "$(sed -n $i'p' /tmp/${NAMEPROG##*/}_NC_names.tmp | awk '{split($1, subfield, "."); print subfield[1]}')" != ${NCNAMES[$i-1]} ]]; then
										sed -i -e $i'i\
										'${NCNAMES[$i-1]}'
										' /tmp/${NAMEPROG##*/}_NC_names.tmp
									fi
								done
								sed -i -e '/^$/d' /tmp/${NAMEPROG##*/}_NC_names.tmp
								rm /tmp/${NAMEPROG##*/}_NC_names.tmp-e
								for (( i = 1; i < 26; i++ )); do
									eval NCFILENAMES[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_NC_names.tmp)"
								done
							fi
							rm /tmp/${NAMEPROG##*/}_NC_names.tmp
							if [[ -f $NAMEFILE1 ]]; then
								while true; do
									printf "\n"
									printf "The directory already present a file (${NAMEFILE1}) homogenized by NC.\nDo you want to overwrite this file? (Y/n)\n"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY]|"" ) 
											cp $DATA $NAMEFILE1
											for i in $(seq 0 24) ; do
												A="${NCFILENAMES[$i]}"
												B="${CHRNAMES[$i]}"
												awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$B'") print "'$A'", $2, $3, $4, $5, $6, $7, $8, $9; else print $0}' $NAMEFILE1 > /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp && mv /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp $NAMEFILE1
											done & PID=$!								
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rHomogenization of the file by 'NC' ${SPIN:$i:1}"
												sleep .1
											done
											printf "\n\n${GREEN}${DATA##*/}${NOCOLOR} has been re-homogenize by 'NC' chromosome names." ""
											break;;
										[nN][oO]|[nN] )
											printf "%s\n" "" "The file already present in the directory will be use for the next steps." ""
											break;;				
				       					* ) 
											printf "\033c"
											printf "%s\n" "" "Please answer yes or no." "";;
				    				esac
								done
							else
								cp $DATA $NAMEFILE1
								for i in $(seq 0 24) ; do
									A="${NCFILENAMES[$i]}"
									B="${CHRNAMES[$i]}"
									awk 'BEGIN{FS="\t"; OFS="\t"}{if ($1=="'$B'") print "'$A'", $2, $3, $4, $5, $6, $7, $8, $9; else print $0}' $NAMEFILE1 > /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp && mv /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp $NAMEFILE1
								done & PID=$!								
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rHomogenization of the file by 'NC' ${SPIN:$i:1}"
									sleep .1
								done
								printf "\n\n${GREEN}${DATA##*/}${NOCOLOR} has been homogenize by 'NC' chromosome names.\n"
							fi
							break;;
						[cC][hH][rR] )
							SORTCHR="^chr"
							NAMEFILE1=${DATA%%.*}_formatChr.$EXTENSION
							NCNAMES=( "NC_000001" "NC_000002" "NC_000003" "NC_000004" "NC_000005" "NC_000006" "NC_000007" "NC_000008" "NC_000009" "NC_000010" "NC_000011" "NC_000012" "NC_000013" "NC_000014" "NC_000015" "NC_000016" "NC_000017" "NC_000018" "NC_000019" "NC_000020" "NC_000021" "NC_000022" "NC_000023" "NC_000024" "NC_012920" )
							if [[ -f $NAMEFILE1 ]]; then
								while true; do
									printf "\n"
									printf "The directory already present a file (${NAMEFILE1}) homogenized by NC.\nDo you want to overwrite this file? (Y/n)\n"
									read ANSWER
									printf "\n"
									case $ANSWER in
										[yY][eE][sS]|[yY]|"" ) 
											cp $DATA $NAMEFILE1
											for i in $(seq 0 24) ; do
												A="${NCNAMES[$i]}"
												B="${CHRNAMES[$i]}"
												awk 'BEGIN{FS="\t"; OFS="\t"}{split($1, subfield, "."); if (subfield[1]=="'$A'") print "'$B'", $2, $3, $4, $5, $6, $7, $8, $9; else print $0}' $NAMEFILE1 > /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp && mv /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp $NAMEFILE1
											done & PID=$!								
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rHomogenization of the file by 'chr' ${SPIN:$i:1}"
												sleep .1
											done		
											printf "${GREEN}${DATA##*/}${NOCOLOR} has been re-homogenize by 'chr' chromosome names.\n"
											break;;
										[nN][oO]|[nN] )
											printf "\n\n${GREEN}${NAMEFILE1}${NOCOLOR} already present in the directory will be use for the next steps.\n"
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
									awk 'BEGIN{FS="\t"; OFS="\t"}{split($1, subfield, "."); if (subfield[1]=="'$A'") print "'$B'", $2, $3, $4, $5, $6, $7, $8, $9; else print $0}'  $NAMEFILE1 > /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp && mv /tmp/${NAMEPROG##*/}_${NAMEFILE1}.tmp $NAMEFILE1
								done & PID=$!								
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rHomogenization of the file by 'chr' ${SPIN:$i:1}"
									sleep .1
								done
								printf "${GREEN}${DATA##*/}${NOCOLOR} has been homogenize by 'chr' chromosome names.\n"
							fi
							break;;				
							* ) 
							printf "\033c"
							printf "%s\n" "" "Please answer NC or chr." "";;
					esac
				done
				if [[ $e -eq 1 ]]; then
					break
				fi
			elif [[ $NCDATA -eq 0  && $CHRDATA -gt 0 ]]; then
				SORTCHR="^chr"
			elif [[ $NCDATA -gt 0 && $CHRDATA -eq 0 ]]; then
				SORTCHR="^NC"
			fi
			if [[ $(grep "$SORTCHR" $DATA | wc -l) -eq $(cat $DATA | wc -l) ]]; then
				printf "\033c"
				printf "%s\n" "SeqIDs of your file are composed exclusively with classical human chromosomes." "You do not need to sort the file by classical human chromosomes." ""
				break
			fi
			while true; do	
				printf "\n"
				printf "Do you want to keep main human chromosomes or the others SeqIDs? (main/other)\n"
				read ANSWER
				printf "\n"
				case $ANSWER in
					[mM]|[mM][aA][iI][nN] ) 
						if [[ $x -eq  0 ]]; then
							NAMEFILE=${DATA%%.*}_mainChrom.$EXTENSION
							DATA=${DATA}
						elif [[ $x -eq  1 ]]; then
							NAMEFILE=${NAMEFILE1%%.*}_mainChrom.$EXTENSION
							DATA=${NAMEFILE1}
						fi
						if [[ -f $NAMEFILE ]]; then
							while true; do
								printf "\n"
								printf "The directory already present a file (${NAMEFILE}) sorted by main chromosomes.\nDo you want to sort again? (Y/n)\n"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY]|"" ) 
										grep "$SORTCHR" $DATA > $NAMEFILE & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rSorting by main human chromosomes in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "\033c"
										printf "\n\n${GREEN}${DATA}${NOCOLOR} has been re-sorted by the main human chromosomes.\n"
										break;;
									[nN][oO]|[nN] )
										printf "\n\n${GREEN}${NAMEFILE}${NOCOLOR} already present in the directory has not been overwritten.\n"
										break;;				
									* ) 
										printf "\033c"
										printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							grep "$SORTCHR" $DATA > $NAMEFILE & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by main human chromosomes ${SPIN:$i:1}"
								sleep .1
							done
							printf "\033c"
							printf "\n\n${GREEN}${DATA}${NOCOLOR} has been sorted by the main human chromosomes.\n"
						fi
						break;;
					[oO]|[oO][tT][hH][eE][rR] )
						if [[ $x -eq  0 ]]; then
							NAMEFILE=${DATA%%.*}_withoutMainChrom.$EXTENSION
							DATA=${DATA}
						elif [[ $x -eq  1 ]]; then
							NAMEFILE=${NAMEFILE1%%.*}_withoutMainChrom.$EXTENSION
							DATA=${NAMEFILE1}
						fi
						if [[ -f $NAMEFILE ]]; then
							while true; do
								printf "\n"
								printf "The directory already present a file (${NAMEFILE}) sorted without main chromosomes.\nDo you want to overwrite it? (Y/n)\n"
								read ANSWER
								printf "\n"
								case $ANSWER in
									[yY][eE][sS]|[yY]|"" ) 
										grep -v "$SORTCHR" $DATA > $NAMEFILE & PID=$!
										i=0 &
										while kill -0 $PID 2>/dev/null; do
											i=$(( (i+1) %4 ))
											printf "\rSorting without main human chromosomes in process ${SPIN:$i:1}"
											sleep .1
										done
										printf "\033c"
										printf "\n\n${GREEN}${DATA}${NOCOLOR} has been re-sorted without main human chromosomes.\n"
										break;;
									[nN][oO]|[nN] )
										printf "\n\n${GREEN}${NAMEFILE}${NOCOLOR} already present in the directory has not been overwritten.\n"
										break;;				
									* ) 
										printf "\033c"
										printf "%s\n" "" "Please answer yes or no." "";;
								esac
							done
						else
							grep -v "$SORTCHR" $DATA > $NAMEFILE & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting without main human chromosomes ${SPIN:$i:1}"
								sleep .1
							done
							printf "\033c"
							printf "\n\n${GREEN}${DATA}${NOCOLOR} has been sorted without main human chromosomes.\n"
						fi
						break;;				
					* ) 
						printf "\033c"
						printf "%s\n" "" "Please answer main or other." "";;
				esac
			done
			((r++))
			question_end
		break
		else
			break
		fi
	done

	##Tool 2: Promoter regions extractor
	while true; do
		if [[ t -eq 2 ]]; then
			printf "\033c"
			TSS=0
			e=0
			if [[ $(cut -f3 $DATA | sort | uniq | wc -l) -eq 1 ]]; then
				REGION=$(cut -f3 $DATA | sort | uniq)
				if [[ "$REGION" == "" ]]; then
					printf "${ORANGE}WARNING:${NOCOLOR} the only region of the file does not present character!\n\n"
				else
					printf "%s\n" "The only region found in the file is '${REGION}'." ""
				fi
				case $REGION in
					[gG][eE][nN][eE]|[gG][eE][nN][eE][sS] )
						while true; do
							printf "All sequences in the file are genes!\nDo you want to explore the 'gene_biotype' to extract promoter from one sub-type of gene? (Y/n)\n"
							read ANSWER
							printf "\n"
							case $ANSWER in
								[yY]|[yY][eE][sS]|"" )
									printf "${ORANGE}WARNING:${NOCOLOR} the file sould have a gff3 structure of attributes (column 9) as follow: XX=XX1;XX=XX;etc...\n\n"
									cut -f9 $DATA | sed -e 's/\;/	/g' > /tmp/${NAMEPROG##*/}_attributes.tmp & PID=$!
									i=0 &
									while kill -0 $PID 2>/dev/null; do
										i=$(( (i+1) %4 ))
										printf "\rExtracting attributes of the genes in the file ${SPIN:$i:1}"
										sleep .1
									done
									printf "\n\n"
									MAXNUMCOL=$(awk 'BEGIN{FS="\t"}{print NF}' /tmp/${NAMEPROG##*/}_attributes.tmp | sort -n | sed -n '$p')
									if [[ $(grep "gene_biotype" /tmp/${NAMEPROG##*/}_attributes.tmp | wc -l) -eq 0 ]]; then
										printf "${ORANGE}WARNING:${NOCOLOR} The attributes of the genes in the file do not present 'gene_biotype'!\n.Promoters region will be extract from all the genes in the file\n\n"
										break
									fi
									for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
										grep "gene_biotype" /tmp/${NAMEPROG##*/}_attributes.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="gene_biotype") print subfield[2]}' >> /tmp/${NAMEPROG##*/}_gene_biotype.tmp
									done
									sed -i -e '/^$/d' /tmp/${NAMEPROG##*/}_gene_biotype.tmp
									sort /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp | uniq > /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp
									rm /tmp/${NAMEPROG##*/}_attributes.tmp
									if [[ $(cat /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp | wc -l) -eq 0 ]]; then
										printf "${ORANGE}WARNING:${NOCOLOR} The genes of your file present only 1 gene_biotype without_character!\n.Promoters region will be extract from all the genes in the file\n\n"
										break
									elif [[ $(cat /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp | wc -l) -eq 1 ]]; then
										printf "${ORANGE}WARNING:${NOCOLOR} The genes of your file present only 1 gene_biotype: "$(cat /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp)". You do not need to sort a specific gene_biotype.\n\n"
										break
									fi
									while true; do
										printf "%s\n" "This are unique contents of 'gene_biotype' present in the file:" "" "Number	type_of_gene_biotype" "$(sort /tmp/${NAMEPROG##*/}_gene_biotype.tmp | uniq -c)" ""									
										NUMOFGENEBIOTYPE=$(cat /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp | wc -l)
										for (( i = 1; i < ${NUMOFGENEBIOTYPE} + 1; i++ )); do
											eval LISTGENBIOTYPE[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp)"
										done
										printf "By which sub-attribute of '${ATTOSORT}' do you want to sort?\n"
										read ANSWER
										printf "\n"
										for (( i = 0; i < ${NUMOFGENEBIOTYPE}; i++ )); do
											if [[ $ANSWER = ${LISTGENBIOTYPE[$i]} ]]; then
												SUBATTOSORT=${LISTGENBIOTYPE[$i]}
											fi
										done
										if [[ ! -z $SUBATTOSORT ]]; then
											NAMEFILE1=${DATA%%.*}_geneBiotypeAttributes_${SUBATTOSORT}Sorted.${EXTENSION}
											if [[ -f $NAMEFILE1 ]]; then
												while true; do
													printf "\nThe directory already present a file (${NAMEFILE1}) sorted by the sub-attribute of gene_biotype '${SUBATTOSORT}'.\nDo you want to sort again? (Y/n)\n"
													read ANSWER
													printf "\n"
													case $ANSWER in
														[yY][eE][sS]|[yY]|"" )
														grep "gene_biotype=${SUBATTOSORT}" $DATA > $NAMEFILE1 & PID=$!
														i=0 &
														while kill -0 $PID 2>/dev/null; do
															i=$(( (i+1) %4 ))
															printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
															sleep .1
														done
														printf "\033c"
														printf "${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the sub-attributeof gene_biotype: ${SUBATTOSORT}\n\n"
														break;;
														[nN][oO]|[nN] )
														printf "\n${GREEN}${NAMEFILE1}${NOCOLOR} already present in the directory has not been overwritten.\n"
														break;;				
								       					* ) 
														printf "%s\n" "" "Please answer yes or no." "";;
								    				esac
												done
											else
												grep "gene_biotype=${SUBATTOSORT}" $DATA > $NAMEFILE1 & PID=$!
												i=0 &
												while kill -0 $PID 2>/dev/null; do
													i=$(( (i+1) %4 ))
													printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
													sleep .1
												done
												printf "\033c"
												printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the sub-attribute of gene_biotype: ${SUBATTOSORT}\n\n"																	
											fi
											break
										else
											printf "\033c"
											printf "%s\n" "" "The sub-attribute of gene_biotype that you wrote is not find in the file." ""
										fi
									done
									rm /tmp/${NAMEPROG##*/}_gene_biotype.tmp
									rm /tmp/${NAMEPROG##*/}_gene_biotype_uniq.tmp
									DATA=${NAMEFILE1}									
									break;;
								[nN]|[nN][oO] )
									printf "\nPromoters region will be extract from all the genes in the file\n"
									break;;
								* )
									printf "%s\n" "" "Please answer yes or no." ""
									;;
							esac
						done
						;;
					[tT][sS][sS] )
						TSS=1
						;;
					* )
						printf "\n${ORANGE}WARNING:${NOCOLOR} the only region of the file is not call 'gene'!\nPlease make sure that the content of your file is gene sequences to be sure to extract promoter regions.\n\n"
				esac
			else
				printf "\n${ORANGE}WARNING:${NOCOLOR} The file contain multiple type of region!\nPlease make sure that the content of your file is gene sequences to be sure to extract promoter regions.\nYou can use the tool 'type of region extractor' to extract gene region from your file.\n\n"
			fi
			if [[ $TSS -eq 0 ]]; then
				printf "\n${ORANGE}WARNING:${NOCOLOR} This tool has been developed to extract promoter regions from Transcription Start Site (TSS) depending of the strand of the gene.\nFor strand +, the TSS is the start point of the sequence, while for Strand -, the TSS is the end point of the sequence.\nIf the strand is not specify, the TSS is the start point of the sequence.\n"
				NAMEFILE2=${DATA%%.*}_TSS.${EXTENSION}
				if [[ -f $NAMEFILE2 ]]; then
					while true; do
						printf "\nThe directory already present a file (${NAMEFILE2}) where TSSs seem to be already extracted.\nDo you want to extract them again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY]|"" )
								awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") print $1,$2,"TSS",$5,$5,$6,$7,$8,$9 ; else print $1,$2,"TSS",$4,$4,$6,$7,$8,$9}' $DATA > $NAMEFILE2 & PID=$!
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rExtraction of TSSs in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "\n\nThe TSSs have been re-extracted from ${GREEN}${DATA##*/}${NOCOLOR}\n"
								break;;
							[nN][oO]|[nN] )
								printf "\n${GREEN}${NAMEFILE2}${NOCOLOR} already present in the directory has not been overwritten.\n"
								break;;				
							* ) 
								printf "%s\n" "" "Please answer yes or no." "";;
						esac
					done
				else
					awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") print $1,$2,"TSS",$5,$5,$6,$7,$8,$9 ; else print $1,$2,"TSS",$4,$4,$6,$7,$8,$9}' $DATA > $NAMEFILE2 & PID=$!
					i=0 &
					while kill -0 $PID 2>/dev/null; do
						i=$(( (i+1) %4 ))
						printf "\rExtraction of TSSs in process ${SPIN:$i:1}"
						sleep .1
					done
					printf "\n\nThe TSSs have been extracted from ${GREEN}${DATA##*/}${NOCOLOR}\n"
				fi
				DATA=${NAMEFILE2}
			else
				awk 'BEGIN{FS="\t"; OFS=" "}{if ($4!=$5) print "Error line", NR}' $DATA > /tmp/${NAMEPROG##*/}_TSS_error.tmp
				if [[ $(cat /tmp/${NAMEPROG##*/}_TSS_error.tmp | wc -l) -gt 0 ]]; then
					printf "\n${RED}Error:${NOCOLOR} one of your sequence presente TSS with a 'start' different to 'end':\nPlease check the TSS at the line:\n"
					cat /tmp/${NAMEPROG##*/}_TSS_error.tmp
					break
				else
					printf "\nThe unique type of region of the file is already ${REGION}, TSSs do not need to be extract from ${GREEN}${DATA##*/}${NOCOLOR}\n"
				fi
			fi
			while true; do
				printf "\nWhich interval around TSS do you want to extract as promoter region?\nPlease answer the interval in base pair as follow: upstream-downstream (ex: 2000-2000)\n"
				read ANSWER
				printf "\n"
				UPSTREAM=${ANSWER%%-*}
				DOWNSTREAM=${ANSWER##*-}
				if [[ $ANSWER =~ [-] && "${UPSTREAM}" =~ ^[0-9]+$ && "${DOWNSTREAM}" =~ ^[0-9]+$ && ${UPSTREAM} -lt 100000 && ${DOWNSTREAM} -lt 100000 ]]; then
					printf "\n${ORANGE}WARNING:${NOCOLOR} This tool has been developed to extract promoter regions from Transcription Start Site depending of the strand of the gene.\nFor strand +, the upstream value will be subtracted to the TSS and the downstream value will be added to the TSS.\nFor Strand -, the upstream value will be added to the TSS and the downstream value will be subtracted to the TSS.\nIf the strand is not specify, the upstream value will be subtracted to the TSS and the downstream value will be added to the TSS.\n\n"
					NAMEFILE=${DATA%%.*}_promoter-${UPSTREAM}to${DOWNSTREAM}bp.${EXTENSION}
					if [[ -f $NAMEFILE ]]; then
						while true; do
							printf "\nThe directory already present a file (${NAMEFILE}) where promoters seem to be already extracted with the same interval (${ANSWER}).\nDo you want to overwrite it? (Y/n)\n"
							read ANSWER
							printf "\n"
							case $ANSWER in
								[yY][eE][sS]|[yY]|"" )
									awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") {gsub($4, $4 - '${DOWNSTREAM}', $4); gsub($5, $5 + '${UPSTREAM}', $5); print $1,$2,"promoter",$4,$5,$6,$7,$8,$9} else {gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $1,$2,"promoter",$4,$5,$6,$7,$8,$9}}' $DATA > $NAMEFILE & PID=$!
									i=0 &
									while kill -0 $PID 2>/dev/null; do
										i=$(( (i+1) %4 ))
										printf "\rExtraction of TSSs in process ${SPIN:$i:1}"
										sleep .1
									done
									printf "\n\nPromoters have been re-extracted with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp from ${GREEN}${DATA##*/}${NOCOLOR}\n"
									break;;
								[nN][oO]|[nN] )
									printf "\n${GREEN}${NAMEFILE2}${NOCOLOR} already present in the directory has not been overwritten.\n"
									break;;				
								* ) 
									printf "%s\n" "" "Please answer yes or no." "";;
							esac
						done
					else
						awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") {gsub($4, $4 - '${DOWNSTREAM}', $4); gsub($5, $5 + '${UPSTREAM}', $5); print $1,$2,"promoter",$4,$5,$6,$7,$8,$9} else {gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $1,$2,"promoter",$4,$5,$6,$7,$8,$9}}' $DATA > $NAMEFILE & PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rExtraction of TSSs in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\n\nPromoters have been extracted with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp from ${GREEN}${DATA##*/}${NOCOLOR}\n"
					fi
					e=1
					break
				else
					printf "%s\n" "Please answer a correct interval as 'upstream-downstream' (ex: 3000-0)." "The interval maximum is '99999-99999'\n"
				fi
			done
			((r++))
			if [[ $e -eq 1 ]]; then
				question_end
			fi			
			break
		else
			break
		fi
	done

	##Tool 3: Extract lines with specific sources
	while true; do
		if [[ t -eq 3 ]]; then
			printf "\033c"
			printf "%s\n" "" "" "This are sources present in the file:" "" "Number_of_line	Source" "$(cut -f2 $DATA | sort | uniq -c)" "" &
			cut -f2 $DATA | sort | uniq | sed 's/ /_/g' > /tmp/${NAMEPROG##*/}_sources.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for sources present in the file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $(awk '/^$/ {x += 1};END {print x }' /tmp/${NAMEPROG##*/}_sources.tmp) -ge 1 ]]; then
				printf "\n${ORANGE}WARNING:${NOCOLOR} 1 of the source does not present character!\nIf you want to sort this source please enter 'without_character'\n\n"
			fi
			if [[ $(wc -l /tmp/${NAMEPROG##*/}_sources.tmp) = "1 /tmp/${NAMEPROG##*/}_sources.tmp" ]]; then
				printf "\033c"
				printf "%s\n" "Only 1 source has been found in the file." "You do not need to sort the file by the database source." ""
				if [[ $(awk '/^$/ {x += 1};END {print x }' /tmp/${NAMEPROG##*/}_sources.tmp) -ge 1 ]]; then
					printf "${ORANGE}WARNING:${NOCOLOR} the only source of the file does not present character!\n"
				fi
				break
			else
				NUMOFSOURCES=$(cat /tmp/${NAMEPROG##*/}_sources.tmp | wc -l)
				for (( i = 1; i < ${NUMOFSOURCES} + 1; i++ )); do
					eval LISTSOURCES[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_sources.tmp)"
				done
			fi
			rm /tmp/${NAMEPROG##*/}_sources.tmp
			while true; do
				printf "\nBy which source do you want to sort? (If the source name present space ' ', please use '_' instead)\n"
				read ANSWER
				printf "\n"
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
						printf $SOURCETOSORT > /tmp/${NAMEPROG##*/}_sourcetosort.tmp
						SOURCETOSORT2="$(sed 's/_/ /g' /tmp/${NAMEPROG##*/}_sourcetosort.tmp)"
						rm /tmp/${NAMEPROG##*/}_sourcetosort.tmp
					fi
					NAMEFILE=${DATA%%.*}_${SOURCETOSORT}SourceSorted.$EXTENSION
					if [[ -f $NAMEFILE ]]; then
					while true; do
						printf "\nThe directory already present a file (${NAMEFILE}) sorted by ${SOURCETOSORT2}\nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY]|"" ) 
								awk 'BEGIN{FS="\t"; OFS="\t"}{ if ($2=="'"$SOURCETOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
								i=0 &
								while kill -0 $PID 2>/dev/null; do
									i=$(( (i+1) %4 ))
									printf "\rSorting by ${SOURCETOSORT2} in process ${SPIN:$i:1}"
									sleep .1
								done
								printf "\033c"
								if [[ $sourcewithoutcharacter -eq 1 ]]; then
									printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the source without character.\n\n"
								else
									printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the source: ${SOURCETOSORT2}\n\n"
								fi
								break;;
							[nN][oO]|[nN] )
								printf "\n${GREEN}${NAMEFILE}${NOCOLOR} file already present in the directory will be use for the next steps.\n"
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
							printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the source without character.\n\n"
						else
							printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the source: ${SOURCETOSORT2}\n\n"
						fi
					fi
					break
				else
					printf "%s\n" "" "The source that you wrote is not find in the file." ""
				fi
			done
			((r++))
			question_end
			break
		else
			break
		fi
	done

	#Tool 4 : Extract lines with specific type of region
	while true; do
		if [[ t -eq 4 ]]; then
			printf "\033c"
			printf "%s\n" "" "" "This are regions present in the file:" "" "Number_of_line	Region" "$(cut -f3 $DATA | sort | uniq -c)" "" &
			cut -f3 $DATA  | sort | uniq | sed 's/ /_/g' > /tmp/${NAMEPROG##*/}_regions.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rLooking for region features present in the file ${SPIN:$i:1}"
				sleep .1
			done
			if [[ $( cat /tmp/${NAMEPROG##*/}_regions.tmp | wc -l) -eq 1 ]]; then
				printf "\033c"
				printf "%s\n" "Only 1 region has been found in the file." "You do not need to sort the file by region." ""
				if [[ $(awk '/^$/ {x += 1};END {print x }' /tmp/${NAMEPROG##*/}_regions.tmp) -ge 1 ]]; then
					printf "${ORANGE}WARNING:${NOCOLOR} the only region of the file does not present character!\n"
				fi
				break
			else
				NUMOFREGIONS=$(cat /tmp/${NAMEPROG##*/}_regions.tmp | wc -l)
				for (( i = 1; i < ${NUMOFREGIONS} + 1; i++ )); do
					eval LISTREGIONS[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_regions.tmp)"
				done
			fi
			if [[ $(awk '/^$/ {x += 1};END {print x }' /tmp/${NAMEPROG##*/}_regions.tmp) -ge 1 ]]; then
				printf "\n${ORANGE}WARNING:${NOCOLOR} 1 of the region does not present character!\nIf you want to sort this region please enter 'without_character'\n\n"
			fi
			rm /tmp/${NAMEPROG##*/}_regions.tmp
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
						printf $REGIONTOSORT > /tmp/${NAMEPROG##*/}_regiontosort.tmp
						REGIONTOSORT2="$(sed 's/_/ /g' /tmp/${NAMEPROG##*/}_regiontosort.tmp)"
						rm /tmp/${NAMEPROG##*/}_regiontosort.tmp
					fi
					NAMEFILE=${DATA%%.*}_${REGIONTOSORT}RegionSorted.$EXTENSION
					if [[ -f $NAMEFILE ]]; then
					while true; do
						printf "\nThe directory already present a file (${NAMEFILE}) sorted by ${REGIONTOSORT2}.\nDo you want to sort again? (Y/n)\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY][eE][sS]|[yY]|"" ) 
							awk 'BEGIN{FS="\t";OFS="\t"}{ if ($3=="'"$REGIONTOSORT2"'") print $0}' $DATA > $NAMEFILE & PID=$!
							i=0 &
							while kill -0 $PID 2>/dev/null; do
								i=$(( (i+1) %4 ))
								printf "\rSorting by ${REGIONTOSORT2} in process ${SPIN:$i:1}"
								sleep .1
							done
							printf "\033c"
							if [[ $regonwithoutcharacter -eq 1 ]]; then
								printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the region without character.\n\n"
							else
								printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the region: ${REGIONTOSORT2}\n\n"
							fi
							break;;
							[nN][oO]|[nN] )
							printf "\n${GREEN}${NAMEFILE}${NOCOLOR} already present in the directory will be use for the next steps.\n"
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
							printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the region without character.\n\n"
						else
							printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the region: ${REGIONTOSORT2}\n\n" 
						fi
					fi
	        		break
				else
					printf "%s\n" "" "The region that you wrote is not find in the file." ""
				fi
			done
			((r++))
			question_end
			break
		else
			break
		fi
	done

	#Tool 5: Attributes explorer
	while true; do
		if [[ t -eq 5 ]]; then
			printf "\033c"
			printf "${ORANGE}WARNING:${NOCOLOR} the file sould have a gff3 structure of attributes (column 9) as follow: XX=XX1;XX=XX;etc...\n\n"
			cut -f9 $DATA | sed -e 's/\;/	/g' > /tmp/${NAMEPROG##*/}_attributes0.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rExtracting attributes present in the file ${SPIN:$i:1}"
				sleep .1
			done
			printf "\n\n"
			MAXNUMCOL=$(awk 'BEGIN{FS="\t"}{print NF}' /tmp/${NAMEPROG##*/}_attributes0.tmp | sort -n | sed -n '$p')
			printf "${MAXNUMCOL} attributes max per line have been found in the file\n\n"
			for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
				awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); print subfield[1]}' /tmp/${NAMEPROG##*/}_attributes0.tmp >> /tmp/${NAMEPROG##*/}_attributes1.tmp
				printf "\rRecovering of the attribute n°${i}"
			done
			printf "\n"
			sed -i -e '/^$/d' /tmp/${NAMEPROG##*/}_attributes1.tmp
			sort /tmp/${NAMEPROG##*/}_attributes1.tmp | uniq -c > /tmp/${NAMEPROG##*/}_numattributes.tmp &
			sort /tmp/${NAMEPROG##*/}_attributes1.tmp | uniq > /tmp/${NAMEPROG##*/}_attributes2.tmp & PID=$!
			i=0 &
			while kill -0 $PID 2>/dev/null; do
				i=$(( (i+1) %4 ))
				printf "\rChecking the number of attributes in the file ${SPIN:$i:1}"
				sleep .1
			done
			rm /tmp/${NAMEPROG##*/}_attributes1.tmp
			s=0
			while true; do
				while true; do
					e=0
					printf "%s\n" "" "" "This are attributes present in the file:" "" "Number	Attribute" "$(cat /tmp/${NAMEPROG##*/}_numattributes.tmp)" ""
					printf "Do you want to extract the list of content from 1 attribute or do you want to sort by one of them? (E/s)\n"
					read ANSWER
					printf "\n"
					case $ANSWER in
						[eE]|[eE][xX][tT][rR][aA][cC][tT] )
							while true; do
								printf "\033c"
								printf "%s\n" "This are attributes present in the file:" "" "Number	Attribute" "$(cat /tmp/${NAMEPROG##*/}_numattributes.tmp)" ""
								NUMOFATTRIBUTE=$(cat /tmp/${NAMEPROG##*/}_attributes2.tmp | wc -l)
								for (( i = 1; i < ${NUMOFATTRIBUTE} + 1; i++ )); do
									eval LISTATTRIBUTE[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_attributes2.tmp)"
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
												[yY][eE][sS]|[yY]|"" ) 
													for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
														grep $ATTOEXTRACT /tmp/${NAMEPROG##*/}_attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOEXTRACT}'") print subfield[2]}' >> $NAMEFILE1
													done
													printf "\nThe list (${GREEN}${NAMEFILE1}${NOCOLOR}) of all content of the attribute '${ATTOEXTRACT}' has been overwritten.\n"
													break;;
												[nN][oO]|[nN] )
													printf "\n${GREEN}${NAMEFILE1}${NOCOLOR} already present in the directory will be use for the next steps.\n"
													break;;				
						       					* ) 
													printf "%s\n" "" "Please answer yes or no." "";;
						    				esac
										done
									else
										for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
											grep $ATTOEXTRACT /tmp/${NAMEPROG##*/}_attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOEXTRACT}'") print subfield[2]}' >> $NAMEFILE1
										done
										printf "\nThe list (${GREEN}${NAMEFILE1}${NOCOLOR}) of all content of the attribute '${ATTOEXTRACT}' has been created.\n"
									fi
									while true; do
										printf "%s\n" "" "Do you to extract unique occurence of the list? (Y/n)" 
										read ANSWER
										printf "\n"
										case $ANSWER in
											[yY]|[yY][eE][sS]|"" )
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
															[yY][eE][sS]|[yY]|"" ) 
																uniq $NAMEFILE1 > $NAMEFILE2
																printf "\nThe list (${GREEN}${NAMEFILE2}${NOCOLOR}) of unique content of the attribute '${ATTOEXTRACT}' has been overwritten.\n"
																break;;
															[nN][oO]|[nN] )
																printf "\n${GREEN}${NAMEFILE2}${NOCOLOR} already present in the directory will be use for the next steps.\n"
																break;;				
									       					* ) 
																printf "%s\n" "" "Please answer yes or no." "";;
									    				esac
													done
												else
													uniq $NAMEFILE1 > $NAMEFILE2
													printf "\nThe list (${GREEN}${NAMEFILE2}${NOCOLOR}) of unique content of the attribute '${ATTOEXTRACT}' has been created.\n"
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
											[yY]|[yY][eE][sS]|"" )
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
								printf "%s\n" "This are attributes present in the file:" "" "Number	Attribute" "$(cat /tmp/${NAMEPROG##*/}_numattributes.tmp)" ""
								NUMOFATTRIBUTE=$(cat /tmp/${NAMEPROG##*/}_attributes2.tmp | wc -l)
								for (( i = 1; i < ${NUMOFATTRIBUTE} + 1; i++ )); do
									eval LISTATTRIBUTE[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_attributes2.tmp)"
								done
								printf "Which attribute do you want to sort?\n"
								read ANSWER
								for (( i = 0; i < ${NUMOFATTRIBUTE}; i++ )); do
									if [[ $ANSWER = ${LISTATTRIBUTE[$i]} ]]; then
										ATTOSORT=${LISTATTRIBUTE[$i]}
									fi
								done
								if [[ ! -z $ATTOSORT ]]; then
									if [[ $(grep "${ATTOSORT}=" /tmp/${NAMEPROG##*/}_attributes0.tmp | wc -l) -eq $(cat /tmp/${NAMEPROG##*/}_attributes0.tmp | wc -l ) ]]; then
										printf "\nThe chosen attribute is present on all line of the file!\n"
										while true; do
											printf "%s\n" "" "Do you to explore the content of '${ATTOSORT}'? (Y/n)" 
											read ANSWER
											printf "\n"
											case $ANSWER in
												[yY]|[yY][eE][sS]|"" )
													for (( i = 1; i < ${MAXNUMCOL}+1; i++ )); do
														grep ${ATTOSORT} /tmp/${NAMEPROG##*/}_attributes0.tmp | awk 'BEGIN{FS="\t"}{split($'$i', subfield, "="); if (subfield[1]=="'${ATTOSORT}'") print subfield[2]}' >> /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp
													done
													if [[ $(cat /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp | uniq | wc -l) -eq $(cat /tmp/${NAMEPROG##*/}_attributes0.tmp | wc -l) ]]; then
														printf "\033c"
														printf "All content of '${ATTOSORT}' seem to be unique \nUse the attribute extraction to obtain the list of the content of '${ATTOSORT}'."
														
														#Ajout la fonction récupe des noms comme id=idXX
													elif [[ $(uniq /tmp/${NAMEPROG##*/}_gene_biotype.tmp | wc -l) -eq 0 ]]; then
														printf "\033c"
														printf "${ORANGE}WARNING:${NOCOLOR} Only 1 type of sub-attribute of '${ATTOSORT}' has been found in the file, but it does have any charater!\nPlease use an other attribute to sort.\n"
													elif [[ $(cat /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp | uniq | wc -l) -eq 1 ]]; then
														printf "\033c"
														printf "Only 1 type of sub-attribute of '${ATTOSORT}' has been found in the file!\n"
														UNIQLINE="$(sed -n '1p' /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp)"
														NAMEFILE=${DATA%%.*}_${ATTOSORT}Attributes_${UNIQLINE}Uniq.${EXTENSION}
														cp $DATA $NAMEFILE
														printf "A copy of the file has been created with the name: ${GREEN}${NAMEFILE}${NOCOLOR}"
													else														
														while true; do
															printf "%s\n" "This are unique content of '${ATTOSORT}' present in the file:" "" "Number	type_of_${ATTOSORT}" "$(sort /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp | uniq -c)" ""
															sort /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp | uniq > /tmp/${NAMEPROG##*/}_${ATTOSORT}uniq.tmp
															NUMOFSUBATTRIBUTE=$(cat /tmp/${NAMEPROG##*/}_${ATTOSORT}uniq.tmp | wc -l)
															for (( i = 1; i < ${NUMOFSUBATTRIBUTE} + 1; i++ )); do
																eval LISTSUBATTRIBUTE[$i-1]="$(sed -n $i'p' /tmp/${NAMEPROG##*/}_${ATTOSORT}uniq.tmp)"
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
																NAMEFILE=${DATA%%.*}_${ATTOSORT}Attributes_${SUBATTOSORT}Sorted.${EXTENSION}										
																if [[ -f $NAMEFILE ]]; then
																	while true; do
																		printf "\nThe directory already present a file (${NAMEFILE}) sorted by the sub-attribute '${SUBATTOSORT}'.\nDo you want to sort again? (Y/n)\n"
																		read ANSWER
																		printf "\n"
																		case $ANSWER in
																			[yY][eE][sS]|[yY]|"" )																			
																			grep "${ATTOSORT}=${SUBATTOSORT}" $DATA > $NAMEFILE & PID=$!
																			i=0 &
																			while kill -0 $PID 2>/dev/null; do
																				i=$(( (i+1) %4 ))
																				printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
																				sleep .1
																			done
																			printf "\033c"
																			printf "${GREEN}${DATA##*/}${NOCOLOR} has been re-sorted by the sub-attribute: ${SUBATTOSORT}\n\n"
																			break;;
																			[nN][oO]|[nN] )
																			printf "\n${GREEN}${NAMEFILE}${NOCOLOR} already present in the directory has not been overwritten.\n"
																			break;;				
													       					* ) 
																			printf "%s\n" "" "Please answer yes or no." "";;
													    				esac
																	done
																else
																	grep "${ATTOSORT}=${SUBATTOSORT}" $DATA > $NAMEFILE & PID=$!
																	i=0 &
																	while kill -0 $PID 2>/dev/null; do
																		i=$(( (i+1) %4 ))
																		printf "\rSorting by ${SUBATTOSORT} in process ${SPIN:$i:1}"
																		sleep .1
																	done
																	printf "\033c"
																	printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the sub-attribute: ${SUBATTOSORT}\n\n"																	
																fi

																break														
															else
																printf "\033c"
																printf "%s\n" "" "The sub-attribute that you wrote is not find in the file." ""
															fi
														done
														rm /tmp/${NAMEPROG##*/}_${ATTOSORT}uniq.tmp
													fi													
													rm /tmp/${NAMEPROG##*/}_${ATTOSORT}.tmp													
													s=1
													break
													;;
												[nN]|[nN][oO] )	
													break;;
												* )
													printf "\033c"
													printf "%s\n" "" "Please answer yes or no." ""
													;;
											esac
										done									
									else
										NAMEFILE=${DATA%%.*}_${ATTOSORT}AttributesSorted.${EXTENSION}										
										if [[ -f $NAMEFILE ]]; then
											while true; do
												printf "\nThe directory already present a file (${NAMEFILE}) sorted by ${ATTOSORT}.\nDo you want to sort again? (Y/n)\n"
												read ANSWER
												printf "\n"
												case $ANSWER in
													[yY][eE][sS]|[yY]|"" ) 
													grep "${ATTOSORT}=" $DATA > $NAMEFILE & PID=$!
													i=0 &
													while kill -0 $PID 2>/dev/null; do
														i=$(( (i+1) %4 ))
														printf "\rSorting by ${ATTOSORT} in process ${SPIN:$i:1}"
														sleep .1
													done
													printf "\033c"
													printf "${GREEN}${DATA##*/}${NOCOLOR}has been re-sorted by the attribute: ${ATTOSORT}\n\n"
													break;;
													[nN][oO]|[nN] )
													printf "\n${GREEN}${NAMEFILE}${NOCOLOR} already present in the directory will has not been overwritten.\n"
													break;;				
							       					* ) 
													printf "%s\n" "" "Please answer yes or no." "";;
							    				esac
											done
										else
											grep "${ATTOSORT}=" $DATA > $NAMEFILE & PID=$!
											i=0 &
											while kill -0 $PID 2>/dev/null; do
												i=$(( (i+1) %4 ))
												printf "\rSorting by ${ATTOSORT} in process ${SPIN:$i:1}"
												sleep .1
											done
											printf "\033c"
											printf "\n${GREEN}${DATA##*/}${NOCOLOR} has been sorted by the attribute: ${ATTOSORT}\n\n"
										fi
										s=1
									fi
									e=1
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
						[yY]|[yY][eE][sS]|"" )
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
			rm /tmp/${NAMEPROG##*/}_attributes2.tmp
			rm /tmp/${NAMEPROG##*/}_numattributes.tmp
			rm /tmp/${NAMEPROG##*/}_attributes0.tmp
			((r++))
			if [[ $s -eq 1 ]]; then
				question_end
			fi
			break
		else
			break
		fi
	done

	#Tool 6: Sequence extender
	while true; do
		if [[ t -eq 6 ]]; then
			printf "\033c"
			e=0
			while true; do
				printf "With which interval do you want to extend the sequences in the file?\nPlease answer the interval in base pair as follow: upstream-downstream (ex: 2000-2000)\n"
				read ANSWER
				printf "\n"
				UPSTREAM=${ANSWER%%-*}
				DOWNSTREAM=${ANSWER##*-}
				if [[ $ANSWER =~ [-] && "${UPSTREAM}" =~ ^[0-9]+$ && "${DOWNSTREAM}" =~ ^[0-9]+$ && ${UPSTREAM} -lt 100000 && ${DOWNSTREAM} -lt 100000 ]]; then
					while true; do
						printf "Do you want to take care of the strand of the sequence? (Y/n)\nIf 'Yes', for sequences with a strand +, the upstream value will be subtracted to the start and the downstream value will be added to the end. While for sequences with a strand -, the upstream value will be added to the end and the downstream value will be subtracted to the start.\nIf 'no', for all sequences, the upstream value will be subtracted to the start and the downstream value will be added to the end.\n"
						read ANSWER
						printf "\n"
						case $ANSWER in
							[yY]|[yY][eE][sS]|"" )
								NAMEFILE=${DATA%%.*}_sequences-${UPSTREAM}to${DOWNSTREAM}bp_strand_dep.${EXTENSION}
								if [[ -f $NAMEFILE ]]; then
									while true; do
										printf "\nThe directory already present a file (${NAMEFILE}) where promoters seem to be already extracted with the same interval (${ANSWER}).\nDo you want to overwrite it? (Y/n)\n"
										read ANSWER
										printf "\n"
										case $ANSWER in
											[yY][eE][sS]|[yY]|"" )
												awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") {gsub($4, $4 - '${DOWNSTREAM}', $4); gsub($5, $5 + '${UPSTREAM}', $5); print $0} else {gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $0}}' $DATA > $NAMEFILE & PID=$!
												i=0 &
												while kill -0 $PID 2>/dev/null; do
													i=$(( (i+1) %4 ))
													printf "\rAddition of the interval -${UPSTREAM}bp-${DOWNSTREAM}bp to each sequence in process ${SPIN:$i:1}"
													sleep .1
												done
												printf "\n\nThe sequences have been re-extended with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp.\nThe file ${GREEN}${NAMEFILE}${NOCOLOR} has been created.\n"
												break;;
											[nN][oO]|[nN] )
												printf "\n${GREEN}${NAMEFILE2}${NOCOLOR} already present in the directory has not been overwritten.\n"
												break;;				
											* ) 
												printf "%s\n" "" "Please answer yes or no." "";;
										esac
									done
								else
									awk 'BEGIN{FS="\t";OFS="\t"}{if ($7=="-") {gsub($4, $4 - '${DOWNSTREAM}', $4); gsub($5, $5 + '${UPSTREAM}', $5); print $0} else {gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $0}}' $DATA > $NAMEFILE & PID=$!
									i=0 &
									while kill -0 $PID 2>/dev/null; do
										i=$(( (i+1) %4 ))
										printf "\rAddition of the interval -${UPSTREAM}bp-${DOWNSTREAM}bp to each sequence in process ${SPIN:$i:1}"
										sleep .1
									done
									printf "\n\nThe sequences have been extended with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp.\nThe file ${GREEN}${NAMEFILE}${NOCOLOR} has been created.\n"
								fi
								break;;
							[nN]|[nN][oO] )
								NAMEFILE=${DATA%%.*}_sequences-${UPSTREAM}to${DOWNSTREAM}bp_strand_indep.${EXTENSION}
								if [[ -f $NAMEFILE ]]; then
									while true; do
										printf "\nThe directory already present a file (${NAMEFILE}) where promoters seem to be already extracted with the same interval (${ANSWER}).\nDo you want to overwrite it? (Y/n)\n"
										read ANSWER
										printf "\n"
										case $ANSWER in
											[yY][eE][sS]|[yY]|"" )
												awk 'BEGIN{FS="\t";OFS="\t"}{gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $0}' $DATA > $NAMEFILE & PID=$!
												i=0 &
												while kill -0 $PID 2>/dev/null; do
													i=$(( (i+1) %4 ))
													printf "\rAddition of the interval -${UPSTREAM}bp-${DOWNSTREAM}bp to each sequence in process ${SPIN:$i:1}"
													sleep .1
												done
												printf "\n\nThe sequences have been re-extended with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp.\nThe file ${GREEN}${NAMEFILE}${NOCOLOR} has been created.\n"
												break;;
											[nN][oO]|[nN] )
												printf "\n${GREEN}${NAMEFILE2}${NOCOLOR} already present in the directory has not been overwritten.\n"
												break;;				
											* ) 
												printf "%s\n" "" "Please answer yes or no." "";;
										esac
									done
								else
									awk 'BEGIN{FS="\t";OFS="\t"}{gsub($4, $4 - '${UPSTREAM}', $4); gsub($5, $5 + '${DOWNSTREAM}', $5); print $0}' $DATA > $NAMEFILE & PID=$!
									i=0 &
									while kill -0 $PID 2>/dev/null; do
										i=$(( (i+1) %4 ))
										printf "\rAddition of the interval -${UPSTREAM}bp-${DOWNSTREAM}bp to each sequence in process ${SPIN:$i:1}"
										sleep .1
									done
									printf "\n\nThe sequences have been extended with the interval -${UPSTREAM}bp to ${DOWNSTREAM}bp.\nThe file ${GREEN}${NAMEFILE}${NOCOLOR} has been created.\n"
								fi
								break;;
							* )
								printf "\033c"
								printf "%s\n" "" "Please answer yes or no." ""
								;;
						esac
					done
					break
				else
					printf "%s\n" "Please answer a correct interval as 'upstream-downstream' (ex: 3000-0)." "The interval maximum is '99999-99999'\n"
				fi
			done
			((r++))
			question_end
			break
		else
			break
		fi
	done

	##Tool 7: GFF to BED file
	while true; do
		if [[ t -eq 7 ]]; then
			while true; do
				CHRNAMES=( "chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY" "chrM" )
				NCNAMES=( "NC_000001" "NC_000002" "NC_000003" "NC_000004" "NC_000005" "NC_000006" "NC_000007" "NC_000008" "NC_000009" "NC_000010" "NC_000011" "NC_000012" "NC_000013" "NC_000014" "NC_000015" "NC_000016" "NC_000017" "NC_000018" "NC_000019" "NC_000020" "NC_000021" "NC_000022" "NC_000023" "NC_000024" "NC_012920" )
				makebed3 () {
					NAMEBED3="${DATA%%.*}.bed3"
					bed3 () {
						awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5}' $DATA > $NAMEBED3
						for i in $(seq 0 24) ; do
							A="${NCNAMES[$i]}"
							B="${CHRNAMES[$i]}"
							awk 'BEGIN{FS="\t"; OFS="\t"}{split($1, subfield, "."); if (subfield[1]=="'$A'") print "'$B'", $2, $3; else print $0}' $NAMEBED3 > /tmp/${NAMEPROG##*/}_${NAMEBED3}.tmp && sort -h /tmp/${NAMEPROG##*/}_${NAMEBED3}.tmp > $NAMEBED3
						done
						rm /tmp/${NAMEPROG##*/}_${NAMEBED3}.tmp
					}
					waitbed3 () {
						PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rCreation of BED3 file in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\033c"
					}
					if [[ -f $NAMEBED3 ]]; then
						while true; do
							printf "%s\n" "" "The directory already present a BED3 file (${NAMEBED3##*/})." "Do you want to overwrite this file? (Y/n)"
							read ANSWER
							printf "\n"
							case $ANSWER in
								[yY][eE][sS]|[yY]|"" ) 
								bed3 & waitbed3
								printf "\n${GREEN}${NAMEBED3##*/}${NOCOLOR} file has been overwritten.\n"
								break;;
								[nN][oO]|[nN] )
								printf "\033c"
								printf "${GREEN}${NAMEBED3##*/}${NOCOLOR} file present in the directory has not been overwritten.\n"
								break;;
								* ) 
								printf "%s\n" "" "Please answer yes or no." "";;
							esac
						done
					else
						bed3 & waitbed3
						printf "\n${GREEN}${NAMEBED3##*/}${NOCOLOR} file has been generated.\n"
					fi
				}
				makebed6 () {
					NAMEBED6="${DATA%%.*}.bed6"
					bed6 () {
						awk 'BEGIN{FS="\t";OFS="\t"}{print $1, $4, $5, $9, $6, $7}' $DATA > $NAMEBED6
						for i in $(seq 0 24) ; do
							A="${NCNAMES[$i]}"
							B="${CHRNAMES[$i]}"
							awk 'BEGIN{FS="\t"; OFS="\t"}{split($1, subfield, "."); if (subfield[1]=="'$A'") print "'$B'", $2, $3, $4, $5, $6; else print $0}' $NAMEBED6 > /tmp/${NAMEPROG##*/}_${NAMEBED6}.tmp && sort -h /tmp/${NAMEPROG##*/}_${NAMEBED6}.tmp $NAMEBED6
						done
						rm /tmp/${NAMEPROG##*/}_${NAMEBED6}.tmp
					}
					waitbed6 () {
						PID=$!
						i=0 &
						while kill -0 $PID 2>/dev/null; do
							i=$(( (i+1) %4 ))
							printf "\rCreation of BED6 file in process ${SPIN:$i:1}"
							sleep .1
						done
						printf "\033c"
					}
					if [[ -f $NAMEBED6 ]]; then
						while true; do
							printf "%s\n" "The directory already present a BED6 file (${NAMEBED6##*/})." "Do you want to overwrite this file? (Y/n)"
							read ANSWER
							printf "\n"
							case $ANSWER in
								[yY][eE][sS]|[yY]|"" )
								bed6 & waitbed6
								printf "\n${GREEN}${NAMEBED6##*/}${NOCOLOR} file has been overwritten.\n"
								break;;
								[nN][oO]|[nN] )
								printf "\033c"
								printf "${GREEN}${NAMEBED6##*/}${NOCOLOR}  file present in the directory has not been overwritten.\n"
								break;;				
   								* ) 
								printf "%s\n" "" "Please answer yes or no." "";;
							esac
						done
					else
						bed6 & waitbed6
						printf "\n${GREEN}${NAMEBED6##*/}${NOCOLOR} file has been generated.\n"
					fi					
				}
				printf "\033c"
				printf "%s\n" "Which can of BED to you want to create with '${DATA##*/}'? (bed3 - bed6 - both)"
				read ANSWER
				case $ANSWER in
					[bB][eE][dD][3] )
						makebed3
						break;;
					[bB][eE][dD][6] )
						makebed6
						break;;
					[bB][oO][tT][hH] )
						makebed3
						makebed6
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
done
