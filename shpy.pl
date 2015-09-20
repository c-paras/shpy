#!/usr/bin/perl -w

#Written by Constantinos Paraskevopoulos in September 2015
#Converts simplistic and moderately complex Shell scripts into Python 2.7 scripts

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(\s*#.*)/) {
		push @code, "$1"; #copies start-of-line comments into python code
	} elsif ($line =~ /^(\s*)echo -n ["'](\s*)["']\s*(#.*)?$/) {
		#converts echo -n with blank string to sys.stdout.write("\s*")
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.stdout.write(\"$2\")";
		import("sys");
	} elsif ($line =~ /^(\s*)echo -n\s*(#.*)?$/) {
		#converts echo -n without args to sys.stdout.write("")
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.stdout.write(\"\")";
		import("sys");
	} elsif ($line =~ /^(\s*)echo\s*(#.*)?$/) {
		#converts echo without args to print without args
		$leading_whitespace = $1;
		push @code, $leading_whitespace."print";
	} elsif ($line =~ /^(\s*)echo ["'](\s*)["']\s*(#.*)?$/) {
		#converts echo with blank string to print with blank string
		$leading_whitespace = $1;
		push @code, $leading_whitespace."print \"$2\"";
	} elsif ($line =~ /^(\s*)echo -n (.+)/) {
		#converts all other calls to echo -n to calls to print
		my ($leading_whitespace, $echo_to_print) = ($1, $2);
		convert_echo($leading_whitespace, $echo_to_print, 0);
	} elsif ($line =~ /^(\s*)echo (.+)/) {
		#converts all other calls to echo to calls to print
		my ($leading_whitespace, $echo_to_print) = ($1, $2);
		convert_echo($leading_whitespace, $echo_to_print, 1);
	} elsif ($line =~ /^(\s*)(chmod|cp|mv)( -.+)* ([^ ]+) ([^ ]+)/) {
		my ($leading_whitespace, $cmd, $options, $arg1, $arg2) = ($1, $2, $3, $4, $5);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option

		#handles the arguments "$*", $[@*], $[0-9]+ and $.+ separately
		my $first_arg = map_option_arg($arg1);
		my $second_arg = map_option_arg($arg2);

		#generates system call string
		if ($arg2 =~ /\$[\@\*]/) {
			$system_call = "['$cmd', '$options', $first_arg] + $second_arg" if $options;
			$system_call = "['$cmd', $first_arg] + $second_arg" if !$options;
		} elsif ($arg2 =~ /\$.+/) {
			$system_call = "['$cmd', '$options', $first_arg, $second_arg]" if $options;
			$system_call = "['$cmd', $first_arg, $second_arg]" if !$options;
		} else {
			$system_call = "['$cmd', '$options', '$first_arg', '$second_arg']" if $options;
			$system_call = "['$cmd', '$first_arg', '$second_arg']" if !$options;
		}

		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(ls|rm)( -.+)* ([^ ]+)/) {
		my ($leading_whitespace, $cmd, $options, $args) = ($1, $2, $3, $4);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option

                #handles the arguments "$*", $[@*], $[0-9]+ and $.+ separately
		my $arg = map_option_arg($args);

		#generates system call string
		if ($args =~ /\$[\@\*]/) {
			$system_call = "['$cmd', '$options'] + $arg" if $options;
			$system_call = "['$cmd'] + $arg" if !$options;
		} elsif ($args =~ /\$.+/) {
			$system_call = "['$cmd', '$options', $arg]" if $options;
			$system_call = "['$cmd', $arg]" if !$options;
		} else {
			$system_call = "['$cmd', '$options', '$arg']" if $options;
			$system_call = "['$cmd', '$arg']" if !$options;
		}

		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(ls|pwd|id|date)( -.+)+/) {
		my ($leading_whitespace, $cmd, $options) = ($1, $2, $3);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option
		$system_call = "['$cmd', '$options'] if $options";
		$system_call = "['$cmd'] if !$options";
		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=`expr (.+)`/) {
		#handles variable initialisation involving 'var=`expr .+`'
		my ($leading_whitespace, $variable) = ($1, $2);
		@shell_exp = split / /, $3;
		my $python_exp = "";

		#converts each expression from shell style to python style
		foreach $expression (@shell_exp) {
			$expression =~ s/\\(.+)/$1/; #converts operators escaped with \
			$expression =~ s/\"(.+)\"/$1/; #converts operators escaped with ""
			$expression =~ s/'(.+)'/$1/; #converts operators escaped with ''
			if ($expression =~ /\$([0-9]+)/) {
				$python_exp .= "sys.argv[$1] "; #handles special vars
				import("sys");
			} elsif ($expression =~ /\$#/) {
				$python_exp .= "(len(sys.argv) - 1) "; #handles '$#' var
				import("sys");
			} elsif ($expression =~ /\$(.+)/) {
				$python_exp .= "int($1) "; #handles all other vars
			} else {
				#copies arithmetic operators and numeric values
				$python_exp .= "$expression ";
			}
		}

		$python_exp =~ s/ $//; #removes trailing ' ' char
		push @code, $leading_whitespace."$variable = $python_exp";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$#/) {
		#handles variable initialisation involving 'var=$#'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = len(sys.argv)";
		import("sys");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$([0-9]+)/) {
		#handles variable initialisation involving 'var=$[0-9]+'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = sys.argv[$3]";
		import("sys");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$(.+)/) {
		#handles variable initialisation involving 'var=$.+'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = $3";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=([0-9]+)/) {
		#handles variable initialisation involving 'var=num'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = $3";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=(.+)/) {
		#handles variable initialisation involving 'var=val'
		my ($leading_whitespace, $name, $value) = ($1, $2, $3);
		$value =~ s/\"(.*)\"/$1/; #removes leading/trailing "
		$value =~ s/'(.*)'/$1/; #removes leading/trailing '
		push @code, $leading_whitespace."$name = '$value'";
	} elsif ($line =~ /^(\s*)cd (.+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."os.chdir('$2')";
		import("os");
	} elsif ($line =~ /^(\s*)exit ([0-9]+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.exit($2)";
		import("sys");
	} elsif ($line =~ /^(\s*)read (.+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = sys.stdin.readline().rstrip()";
		import("sys");
	} elsif ($line =~ /^(\s*)for (.+) in \"\$\*\"/) {
		#handles for loops involving "$*"
		$leading_whitespace = $1;
		push @code, $leading_whitespace."for $2 in ' '.join(sys.argv[1:]):";
	} elsif ($line =~ /^(\s*)for (.+) in \"?\$[\@\*]/) {
		$leading_whitespace = $1;
		#handles for loops involving $[@*]
		push @code, $leading_whitespace."for $2 in sys.argv[1:]:";
	} elsif ($line =~ /^(\s*)for (.+) in ([^\?\*]+)/) {
		my ($leading_whitespace, $loop_variable) = ($1, $2);
		@args = split / /, $3;

		#appends each arg to loop in the format <arg> or '<arg>'
		foreach $arg (@args) {
			if ($arg =~ /[0-9]+/) {
				$loop_args .= "$arg, "; #formats numeric values
			} else {
				$loop_args .= "'$arg', "; #formats words
			}
		}

		$loop_args =~ s/, $/:/; #converts last instance of ", " to :
		push @code, $leading_whitespace."for $loop_variable in $loop_args";
	} elsif ($line =~ /^(\s*)for (.+) in (.+)/) {
		my ($leading_whitespace, $loop_variable, $file_type) = ($1, $2, $3);
		push @code, $leading_whitespace."for $loop_variable in sorted(glob.glob(\"$file_type\")):";
		import("glob");
	} elsif ($line =~ /^(\s*)(if|elif|while) test -e (.+)/) {
		my ($leading_whitespace, $control, $file) = ($1, $2, $3);
		push @code, $leading_whitespace."$2 os.path.exists('$file'):";
		import("os");
	} elsif ($line =~ /^(\s*)(if|elif|while) test -([rwx]) (.+)/) {
		my ($leading_whitespace, $control, $rwx, $file) = ($1, $2, $3, $4);
		$rwx =~ tr/rwx/RWX/;
		push @code, $leading_whitespace."$control os.access('$file', os.$rwx"."_OK):";
		import("os");
	} elsif ($line =~ /^(\s*)(if|elif|while) test -f (.+)/) {
		my ($leading_whitespace, $control, $file) = ($1, $2, $3);
		push @code, $leading_whitespace."$control os.path.isfile('$file'):";
		import("os");
	} elsif ($line =~ /^(\s*)(if|elif|while) test -d (.+)/) {
		my ($leading_whitespace, $control, $file) = ($1, $2, $3);
		push @code, $leading_whitespace."$control os.path.isdir('$file'):";
		import("os");
	} elsif ($line =~ /^(\s*)(if|elif|while) test -h (.+)/) {
		my ($leading_whitespace, $control, $file) = ($1, $2, $3);
		push @code, $leading_whitespace."$control os.path.islink('$file'):";
		import("os");
	} elsif ($line =~ /^(\s*)(if|elif|while) (true|false)/) {
		#handles if/elif/while with negated true/false
		my ($leading_whitespace, $control, $cmd) = ($1, $2, $3);
		push @code, $leading_whitespace."$control not subprocess.call(['$cmd']):";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(if|elif|while) (diff|fgrep)( -.+)* ([^ ]+) ([^ ]+)/) {
		#handles if/elif/while with negated diff/fgrep
		my ($leading_whitespace, $control, $cmd, $options, $file1, $file2) = ($1, $2, $3, $4, $5, $6);
		$file1 = map_option_arg($file1);
		$file2 = map_option_arg($file2);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option
		$system_call = "['$cmd', '$options', $file1, $file2]" if $options;
		$system_call = "['$cmd', $file1, $file2]" if !$options;
		push @code, $leading_whitespace."$control not subprocess.call($system_call):";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(if|elif|while) test ([^ ]+) -?([^ ]+) ([^ ]+)/) {
		#handles all other if/elif/while
		my ($leading_whitespace, $control, $first, $shell_operator, $second) = ($1, $2, $3, $4, $5);
		$operator = convert_operator($shell_operator);

		#maps variables to their python analogues
		if ($first =~ /^\$/) {
			$map_first = $first;
			$map_first =~ s/^\$//;
			$arg1 = map_special_variable($map_first);
		} else {
			$arg1 = $first;
		}

		#maps variables to their python analogues
		if ($second =~ /^\$/) {
			$map_second = $second;
			$map_second =~ s/^\$//;
			$arg2 = map_special_variable($map_second);
		} else {
			$arg2 = $second;
		}

		#appends numeric comparisons
		push @code, $leading_whitespace."$control int($arg1) $operator int($arg2):" if $shell_operator !~ /=/;

		#appends line depedning on whether first and/or second is a variable
		if ($first =~ /^\$/ && $second =~ /^\$/ && $shell_operator =~ /=/) {
			push @code, $leading_whitespace."$control $arg1 $operator $arg2:";
		} elsif ($first !~ /^\$/ && $second !~ /^\$/ && $shell_operator =~ /=/) {
			push @code, $leading_whitespace."$control '$arg1' $operator '$arg2':";
		} elsif ($first =~ /^\$/ && $second !~ /^\$/ && $shell_operator =~ /=/) {
			push @code, $leading_whitespace."$control $arg1 $operator '$arg2':";
		} elsif ($first !~ /^\$/ && $second =~ /^\$/ && $shell_operator =~ /=/) {
			push @code, $leading_whitespace."$control '$arg1' $operator $arg2:";
		}

	} elsif ($line =~ /^(\s*)else/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."else:"; #translates 'else' into 'else:'
	} elsif ($line =~ /^\s*(do|done|then|fi)/) {
		push @code, " "; #appends blank line for correct alignment of comments
	} elsif ($line =~ /^\s*$/) {
		push @code, ""; #transfers blank lines for correct alignment of comments
	} else {
		#converts all other lines into untranslated comments
		push @code, "#$line [UNTRANSLATED CODE]";
	}

	#stores end-of-line comments in a hash aligned with current line of code
	if ($line =~ /(\s+#.*)$/ && $line !~ /^\s*#.*$/) {
		#second regex avoids re-matching start-of line comments
		$comments{$code[$#code]} = $1;
	}

}

#copies end-of-line comments into python source code
$i = 0;
for ($i..$#code) {
	$code[$i] .= $comments{$code[$i]} if $comments{$code[$i]}; #appends comment to end of line
	$i++;
}

#prints rendered python code to stdout
unshift @code, "#Converted by shpy.pl [".(scalar localtime)."]\n";
unshift @code, "$interpreter\n" if $interpreter;
foreach $line (@code) {
	print "$line\n" if $line ne " ";
}

#prepends an import of the given package to the code if not already present
sub import {
	my $package = $_[0];
	unshift @code, "import $package" if !grep(/^import $package$/, @code);
}

#converts numeric and non-numeric test operators to python style operators
sub convert_operator {
	my $operator = $_[0];

	if ($operator eq "eq") {
		return "==";
	} elsif ($operator eq "=" || $operator eq "==") {
		return "==";
	} elsif ($operator eq "ne") {
		return "!=";
	} elsif ($operator eq "lt") {
		return "<";
	} elsif ($operator eq "le") { 
		return "<=";
	} elsif ($operator eq "gt") {
		return ">";
	} elsif ($operator eq "ge") {
		return ">=";
	}

}

#converts calls to echo to calls to print
sub convert_echo {
	my ($leading_whitespace, $echo_to_print, $print_newline) = @_;

	#handles the case where entire string passed to echo is within single quotes
	if ($echo_to_print =~ /^'.*'$/) {
		$echo_to_print =~ s/'//g;
		if ($print_newline == 1) {
			push @code, $leading_whitespace."print '$echo_to_print'";
		} elsif ($print_newline == 0) {
			push @code, $leading_whitespace."sys.stdout.write('$echo_to_print')";
			import("sys");
		}
		return;
	}

	$interpolate_variables = 1 if $echo_to_print =~ /^\".*\"$/;
	$interpolate_variables = 0 if $echo_to_print !~ /^\".*\"$/;
	$echo_to_print =~ s/"//g; #removes all occurrences of double quotes from string
	my @words = split / /, $echo_to_print;
	$string_to_print = "";
	my $i = 0;

	#handles each 'word' on echo line
	while ($i <= $#words) {

		#removes $ from variables and formats words as <var> or '<var>'
		if ($words[$i] =~ /\$/) {
			append_variables($words[$i]);
		} else {
			$string_to_print .= "\"$words[$i]\", " if $words[$i];
		}

		$i++;
	}

	$string_to_print =~ s/, $// if $print_newline; #removes trailing ', '
	push @code, $leading_whitespace."print $string_to_print" if $print_newline;
	push @code, $leading_whitespace."print $string_to_print" if !$print_newline && $string_to_print;
	push @code, $leading_whitespace."sys.stdout.write('')" if !$print_newline;
}

#appends variables and adjacent chars/single quotes to string to be printed
sub append_variables {
	my ($word, $match) = @_;
	my @words = split /\$/, $word;

	#deals with the case of the variable being '$var1[$varn]*'
	if ($word =~ /^'+(.+)'+$/ && $interpolate_variables == 0) {
		$string_to_print .= "\"$1\", ";
		return;	
	}

	$words[0] =~ s/'//g if $interpolate_variables == 0;
	$string_to_print .= "\"$words[0]\" + " if $word =~ /^([^\$]+)\$/; #appends leading chars

	#deals with variables of the form $var1[$varn]*
	my $i = 1;
	while ($i < $#words) {
		#filters out empty strings
		$i++ if $words[$i] =~ /^$/;
		last if $i > $#words;

		$words[$i] =~ s/'//g; #removes ' chars
		my $mapped_variable = map_special_variable($words[$i]);
		$string_to_print .= "$mapped_variable + ";
		$i++;
	}

	$words[$i] =~ s/'//g; #removes ' chars
	my $mapped_variable = map_special_variable($words[$i]);
	$string_to_print .= "$mapped_variable, " if $word !~ /('+)$/;

	#re-appends ' chars
	$string_to_print .= "$mapped_variable + " if $word =~ /('+)$/ && $interpolate_variables == 1;
	$string_to_print .= "$mapped_variable, " if $word =~ /('+)$/ && $interpolate_variables == 0;
	
	#appends trailing '+ whenever entire string is double quoted
	$string_to_print .= "\"$1\", " if $word =~ /('+)$/ && $interpolate_variables == 1;
}

#maps shell metavariables to their python analogues
sub map_special_variable {
	my $var = $_[0];

	#handles ordinary variables
	if ($var =~ /[a-zA-Z_][a-zA-Z0-9_]*/) {
		return $var;
	}

	#handles special variables
	import("sys");
	if ($var =~ /^[0-9]+$/) {
		return "sys.argv[$var]";
	} elsif ($var =~ /^\@$/) {
		return "sys.argv[1:]";
	} elsif ($var =~ /^\*$/ && $interpolate_variables == 0) {
		return "sys.argv[1:]";
	} elsif ($var =~ /^\*$/ && $interpolate_variables == 1) {
		return "' '.join(sys.argv[1:])";
	} elsif ($var =~ /^\#$/) {
		return "(len(sys.argv) - 1)";
	}

}

#maps options or arguments to their interpolated values
sub map_option_arg {
	my $input = $_[0];
	if ($input =~ /^\"\$(.+)\"/) {
		$interpolate_variables = 1;
		$input = map_special_variable($1);
	} elsif ($input =~ /^('\$.+')$/) {
		$input =~ $1;
	} elsif ($input =~ /^\$/) {
		$input =~ s/^\$//;
		$interpolate_variables = 0;
		$input = map_special_variable($input);
	} else {
		$input = $input;
	}
	return $input;
}
