#!/usr/bin/env fish

# Load library
begin
	set --global --export pku_copyleft__websiteUrl 'http://162.105.134.201'

	function download
		curl --location --compressed --user-agent 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2725.0 Safari/537.36' --referer "$pku_copyleft__websiteUrl/pdfindex.jsp?fid=$pku_copyleft__fid" --retry 5 --silent --show-error --cookie "JSESSIONID=$pku_copyleft__jsessionid" $argv
	end

	function getTitleAndStartAndEndPageNumbers
		set --local file_temp (mktemp)
		download --output "$file_temp" -- "$pku_copyleft__websiteUrl/pdfindex.jsp?fid=$pku_copyleft__fid"
		#set --global title (cat -- "$file_temp" | pup 'body > input[id="infoname"] json{}' | jq --raw-output '.[0].value')
		cat -- "$file_temp" | pup 'body > input[id="infoname"] json{}' | jq --raw-output '.[0].value'
		#set --global startPageNumber (cat -- "$file_temp" | pup 'body > input[id="startpage"] json{}' | jq --raw-output '.[0].value')
		cat -- "$file_temp" | pup 'body > input[id="startpage"] json{}' | jq --raw-output '.[0].value'
		#set --global endPageNumber (cat -- "$file_temp" | pup 'body > input[id="endpage"] json{}' | jq --raw-output '.[0].value')
		cat -- "$file_temp" | pup 'body > input[id="endpage"] json{}' | jq --raw-output '.[0].value'
		rm -- "$file_temp"
	end

	function downloadPage --argument-names pageNumber dir_output
		set --local zeroBasedPageNumber (math -- "$pageNumber" - 1)
		set --local pageUrl (download -- "$pku_copyleft__websiteUrl/jumpServlet?page=$zeroBasedPageNumber&fid=$pku_copyleft__fid" | jq --raw-output '.list[] | select(.id == "'"$zeroBasedPageNumber"'") | .src')
		download --output "$dir_output"/"$pageNumber"'.jpg' -- "$pageUrl"
	end

	switch "$pku_copyleft__loadLibraryOnly"
	case 1
		exit 0
	case '*'
		set --global --export pku_copyleft__loadLibraryOnly 1
	end
end

# Check dependencies
begin
	set --global dependencies 'fish' 'curl' 'jq' 'pup' 'img2pdf'
	set --global optionalDependencies 'parallel' 'ocrmypdf'
	set --global missingDependencies
	for dependency in $dependencies
		if not command -q "$dependency"
			set --append missingDependencies "$dependency"
		end
	end
	if test -n "$missingDependencies"
		echo 'Error: Please install dependencies: '(string join -- ', ' $missingDependencies) >&2
		exit 3
	end
end

set --global --export pku_copyleft__file_script (realpath -- (status 'filename'))

function help
	echo 'Usage:  '(status 'filename')' -c <JSESSIONID> -f <fid> [-o <directory>] [-l <languages>]'
	echo 'Download theses from Peking University'
	echo
	echo 'Options:'
	echo '        -c, --cookie=<JSESSIONID>     Cookie "JSESSIONID" (look up in the browser)'
	echo '        -f, --fid=<fid>               "fid" of the thesis (see URL of the thesis, e.g. "http://162.105.134.201/pdfindex.jsp?fid=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")'
	echo '        -o, --output-dir=<directory>  Specify output directory (default: $PWD)'
	echo '        -l, --language=<languages>    Language(s) of the file to be OCRed (see `tesseract --list-langs` for all language packs installed in your system). Use `-l eng+deu` for multiple languages'
	echo '        -h, --help                    Display this help message'
end

# Parse options
begin
	set --local optionSpecs \
		--name 'pku_copyleft' \
		(printf '--exclusive\nh,%s\n' c f o l) \
		(fish_opt --short 'c' --long 'cookie' --required-val) \
		(fish_opt --short 'f' --long 'fid' --required-val) \
		(fish_opt --short 'o' --long 'output-dir' --required-val) \
		(fish_opt --short 'l' --long 'language' --required-val) \
		(fish_opt --short 'h' --long 'help')
	if not argparse $optionSpecs -- $argv
		help
		exit 2
	end
	if test -n "$_flag_h"
		help
		exit 0
	end
	if test (count $argv) -gt 0
		echo 'Error: Extraneous arguments: '"$argv" >&2
		help
		exit 2
	end
	set --global --export pku_copyleft__jsessionid "$_flag_c"
	set --global --export pku_copyleft__fid "$_flag_f"
	if test -z "$pku_copyleft__jsessionid" || test -z "$pku_copyleft__fid"
		echo 'Error: Please provide cookie "JSESSIONID" and "fid" of the thesis' >&2
		help
		exit 2
	end
	set --global dir_output "$_flag_o"
	if test -z "$dir_output"
		#set dir_output (pwd)
		set dir_output "$PWD"
	end
	set --global ocrLanguages "$_flag_l"
end

# Get filename and page numbers
begin
	set --local titleAndStartAndEndPageNumbers (getTitleAndStartAndEndPageNumbers)
	set --global title "$titleAndStartAndEndPageNumbers[1]"
	set --global startAndEndPageNumbers $titleAndStartAndEndPageNumbers[2 3]
	if test "$startAndEndPageNumbers[2]" = 'null' || test "$startAndEndPageNumbers[3]" = 'null'
		echo 'Error: Please check cookie "JSESSIONID" and "fid" of the thesis' >&2
		exit 1
	end
	set --global output "$dir_output"/"$title"'.pdf'
	if test -e "$output" || test -L "$output"
		echo 'Error: File exists: '"$output" >&2
		exit 1
	end
end

# Download PDF
begin
	set --local --export pku_copyleft__dir_temp (mktemp -d)
	if command -q 'parallel'
		PARALLEL_SHELL=(command -v 'fish') parallel 'source -- "$pku_copyleft__file_script" ; downloadPage "{}" "$pku_copyleft__dir_temp"' ::: (seq $startAndEndPageNumbers)
	else
		echo 'Warning: Please install "parallel" to increase download speed' >&2
		for pageNumber in (seq $startAndEndPageNumbers)
			#downloadPage "$pageNumber" "$pku_copyleft__dir_temp"
			fish --init-command='source -- "$pku_copyleft__file_script"' --command='downloadPage "'"$pageNumber"'" "$pku_copyleft__dir_temp"' &
		end
		wait
	end
	if command -q 'ocrmypdf' && test -n "$ocrLanguages"
		img2pdf -- "$pku_copyleft__dir_temp"/*.jpg | ocrmypdf --title="$title" --language="$ocrLanguages" -- - "$output"
	else
		img2pdf --output="$output" -- "$pku_copyleft__dir_temp"/*.jpg
		if test -n "$ocrLanguages"
			echo 'Error: Please install "ocrmypdf" to enable OCR function' >&2
		end
	end
	rm -rf -- "$pku_copyleft__dir_temp"
end
