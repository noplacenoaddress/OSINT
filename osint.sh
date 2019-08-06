#!/bin/bash

#  Author       : taglio
#  Date         : Fri May 03 10:28:13 Europe/Madrid 2019

help(){
  echo "This is a Shell-Script that help you to process diskimages for OSINT"
  echo "NPNA - no place no address"
  echo
  echo "Usage : ./${0##*/} [OPTION] {COMMAND}"
  echo "  Available Options:"
  echo "           -f [file]        Scan file"
  echo "           -h               Show this help"
  echo
}

extract(){
	if [ ! -d $1 ]; then
		mkdir -p $1/photorec
		mkdir $1/binwalk
		mkdir $1/results
	fi
	echo "Ejecuting binwalk"
	echo
	if [ ! -f $1/results/binwalk.txt ]; then
         	#binwalk --dd='.*' --size=0x2500000 --directory=$1/binwalk $1.dd > $1/results/binwalk.txt
		binwalk -v --directory=$1/binwalk $1.dd > $1/results/binwalk.txt
	fi
	echo "Ejecuting photorec"
	echo
	if [ ! -f $1/results/photorec.log ]; then
		photorec /log $1.dd
		mv photorec.log $1/results
	fi	
	echo "Mounting loop image"
	echo
	udisksctl loop-setup -r -f $1.dd
	mountdir=`mount | tail -n 1 | awk '{print $3}'`
	cp -Rp $mountdir $1/
	tree $mountdir > $1/results/tree-original.txt
	umount -v $mountdir
}

process(){
	cd $2/$1
	echo "Ejecuting exiftool"
	echo
	exiftool images/ > $2/$1/results/exif.txt
	echo "Ejecuting strings in binary"
	echo
	strings -n 8 binary/* > $2/$1/results/strings-binary.txt
	echo "Ejecuting strings in mail"
	echo
	strings -n 8 mail/* > $2/$1/results/strings-mail.txt
	echo "Ejecuting ffprobe in audio"
	echo
	touch $2/$1/results/ffprobe-audio.txt
	for "item" in $(find audio/* -type f); do
		ffprobe "$item" >> $2/$1/results/ffprobe-audio.txt
	done
	echo "Ejecuting ffprobe in video"
	echo
	touch $2/$1/results/ffprobe-video.txt
	for "item" in $(find video/* -type f); do
		ffprobe "$item" >> $2/$1/results/ffprobe-video.txt
	done
	echo "Ejecuting vt in binary"
	echo
	md5sum binary/* > results/md5sum-binary.txt
	cat results/md5sum-binary.txt | cut -d ' ' -f1 | vt file - > results/vt.txt
	#cat 128/results/md5sum.txt | cut -d ' ' -f1 | vt download -
	echo "Ejecuting stegdetect in images"
	echo
	touch $2/$1/results/stegdetect-jpeg.txt
	for "item" in $(find images/*.jpg -type f); do
		stegdetect -tF "$item" >> $2/$1/results/stegdetect-jpeg.txt
	done
}

organize(){
	
	cd $2/$1
	if [ ! -d "images" ]; then
		mkdir images
	fi
	if [ ! -d "binary" ]; then
		mkdir binary
	fi
	if [ ! -d "text" ]; then
		mkdir text
	fi
	if [ ! -d "archive" ]; then
		mkdir archive
	fi
	if [ ! -d "audio" ]; then
		mkdir audio
	fi
	if [ ! -d "video" ]; then
		mkdir video
	fi
	if [ ! -d "code" ]; then
		mkdir code
	fi
	if [ ! -d "office" ]; then
		mkdir office
	fi
	if [ ! -d "database" ]; then
		mkdir database
	fi
	if [ ! -d "mail" ]; then
		mkdir mail
	fi
	if [ ! -d "diskimages" ]; then
		mkdir diskimages
	fi
	if [ ! -d "unknown" ]; then
		mkdir unknown
	fi
	for item in $(find photorec/recup_* -type f); do			
		case $item in
			*[jJ][pP][gG]|*[jJ][pP][eE][gG]|*[tT]?[fF]|*[gG][iI][fF]|*[pP][nN][gG]|*[bB][mM][pP]|*[sS][vV][gG]|*[wW][eE][bB][pP]|*[iI][cC][oO]|*[pP][gG][mM]|*[eE][mM][fF]|*[aA][nN][iI]|*[hH][dD][rR]|*[pP][pP][mM]|*[pP][cC][xX]|*[wW][iI][mM])
				mv $item images/
				;;
			*[eE][xX][eE]|*?[lL][lL]|*[sS][yY][sS]|*[aA][pP][pP][lL][eE]|*[eE][lL][fF]|*[dD][aA][tT]|*32|*[cC][lL][aA][sS][sS]|*[jJ][aA][rR]|*[dD][rR][vV]|*[lL][nN][kK]|*[pP][fF]|*[aA][pP][iI][sS][eE][tT][sS][tT][uU][bB]|*[oO][cC][xX]|*[mM][uU][iI]|*[tT][lL][bB]|*[fF][aA][eE]|*[cC][oO][mM]|*[eE][fF][iI])
				mv $item binary/
				;;
			*[tT][xX]?|*[rR][tT][fF]|*[cC][hH][mM]|*[eE][vV][tT]|*[vV][dD][mM])
				mv $item text/
				;;
			*[gG][zZ]|*[zZ][iI][pP]|*7[zZ]|*[cC][aA][bB]|*[oO][lL][bB]|*[tT][aA][rR]|*[aA]|*[lL][iI][tT])
				mv $item archive/
				;;
			*[aA][iI][fF]|*[mM][pP]3|*[wW][pP][lL]|*[wW][aA][vV]|*[tT][sS]|*[aA][mM][rR])
				mv $item audio/
				;;
			*[vV][mM]?|*[mM][oO][vV]|*[mM][pP]4|*[aA][vV][iI]|*[mM][iI][dD]|*[sS][wW]?|*[wW][eE][bB][mM]|*[aA][xX]|*[mM][pP][gG]|*[mM][pP][eE][gG])
				mv $item video/
				;;
			*[cC]|*[jJ][aA][vV]?|*[hH]|*[hH][tT][mM]|*[xX][mM][lL]|*[iI][nN][fF]|*[rR][eE][gG]|*[bB][aA][tT]|*[oO][cC][xX]|*[iI][nN][iI]|*[jJ][sS][pP]|*[fF]|*[pP][lL][iI][sS][tT]|*[dD][tT][aA]|*[pP][yY]|*[kK][mM][zZ])
				mv $item code/
				;;
			*[pP][pP][tT]|*[xX][lL]*|*[dD][oO][cC][xX]|*[pP][dD][fF]|*[wW][kK]4|*[aA][cC][cC][bB][bB]|*[cC][sS][vV]|*[sS][xX][wW]|*[oO][dD]?|*[vV][sS][dD]|*[mM][pP][pP]|*[oO][nN][eE]|*[sS][nN][tT]|*[dD][oO][cC]|*[wW][kK][sS]|*[pP][pP][tT][xX])
				mv $item office/
				;;
			*[sS][qQ][lL][iI][tT][eE]|*[dD][bB]|*[dD][bB]?)
				mv $item database/
				;;	
			*[mM][bB][oO][xX]|*[pP][sS][tT]|*[wW][aA][bB])
				mv $item mail/
				;;
			*[fF][aA][tT])
				mv $item diskimages/
				;;
			*)
				mv $item unknown/
				;;																		
		esac
	done
	rm -rf photorec/recup_*
	cd $2/$1
	for item in $(find binwalk/ -type f); do
		type=`file $item | awk '{print $2 $3}'`
		case $type in
		 	data)
				mime=`mimetype -a "$item" | awk '{print $2}'`
				case $mime in
					text/plain)
						mv $item text/
						;;
					*)
						mv $item unknown/
						;;
				esac
				;;
			PE32executable|MS-DOSexecutable|PE32+executable)
				mv $item binary/
				;;
			PCbitmap,|PNGimage|JPEGimage|TIFFimage)
				mv $item images/
				;;
			zlibcompressed)
				mv $item images/
				;;
			ciscoIOS|COBALTboot|DOS/MBRboot|VMware4disk)
				mv $item diskimages/
				;;
			MySQLISAM)
				mv $item database/
				;;
			ASCIIcpio)
				mv $item archive/
				;;
			*)
				mv $item unknown/
				;;
		esac	
	done
	
	
}

catalog(){
	cd $2/$1 
	lastdirorig=`head -n 1 results/tree-original.txt | rev | cut -d "/" -f1 | rev`
	sqlite3 results/$1.sqlite "CREATE table items (id INTEGER PRIMARY KEY NOT NULL,md5sum TEXT NOT NULL, filename TEXT NOT NULL, path TEXT NOT NULL, mtime TEXT NOT NULL);"
	for "item" in $(find $lastdirorig/ -type f); do
		md5=`md5sum "$item" | cut -d ' ' -f1`
		mtime=$(ls -ul "$item"| awk '{print $6" "$7" "$8}')
		sqlite3 results/$1.sqlite "INSERT INTO items (md5sum, filename, path, mtime) VALUES (\"$md5\", \"$item\", \"$2/$1\", \"$mtime\");"
	done
	for "item" in $(find . -type f |grep -v results/ | grep -v $lastdirorig); do
		md5=`md5sum "$item" | cut -d ' ' -f1`
		"resql"=$(sqlite3 results/$1.sqlite "SELECT id,filename,path FROM items WHERE md5sum=\"$md5\" ")
		if [ -z "$resql" ]; then
			echo "$resql"
			mtime=$(ls -ul "$item"| awk '{print $6" "$7" "$8}')
			sqlite3 results/$1.sqlite "INSERT INTO items (md5sum, filename, path, mtime) VALUES (\"$md5\", \""$item"\", \"$2/$1\",  \"$mtime\");"
		else
			rm "$item"
		fi
	done
}

case "$1" in
-f)
	if [ ! -f "$2" ] ; then
		echo "[!] cannot access $2: No such file"
		echo
	exit 1
	else	
		base=`pwd`
		target=`echo $2 | cut -d '.' -f1`
		if [ ! -d $target ]; then
			extract "$target"
		fi
		organize "$target" "$base"
		catalog "$target" "$base"
		process "$target" "$base"
	fi
	echo "Ejecuting tree in the root"
	echo
	cd $base/$target
	tree > results/tree.txt
	fdisk -l ../$2 > results/fdisk.txt
	sfdisk -d ../$2 > results/part_table
;;
*)
	help
	exit 1
;;
esac
