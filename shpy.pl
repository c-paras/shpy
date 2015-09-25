#!/usr/bin/perl -w
#Written by Constantinos Paraskevopoulos in September 2015
#Converts simplistic and moderately complex Shell scripts into Python 2.7 scripts

$tab_count = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	#reformats current line
	chomp $line;
	$line =~ s/\s*$//;
	$line =~ s/^\s*//;
	$line = indent_code($line);
	$comment = "";

	#saves comment in variable and removes it from line to simplify pattern matching
	if ($line =~ /(\s+#.*)$/ && $line !~ /^\s*#.*$/) {
		#second regex avoids matching start-of line comments
		$comment = $1;
		$line =~ s/$1$//;
	}

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(\s*#.*)/) {
		push @code, "$1"; #copies start-of-line comments into python code
	} elsif ($line =~ /^(\s*)echo -n ["'](\s*)["']$/) {
		#converts echo -n with blank string to sys.stdout.write("\s*")
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.stdout.write(\"$2\")";
		import("sys");
	} elsif ($line =~ /^(\s*)echo -n$/) {
		#converts echo -n without args to sys.stdout.write("")
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.stdout.write(\"\")";
		import("sys");
	} elsif ($line =~ /^(\s*)echo ["'](\s*)["']$/) {
		#converts echo with blank string to print with blank string
		$leading_whitespace = $1;
		push @code, $leading_whitespace."print \"$2\"";
	} elsif ($line =~ /^(\s*)echo$/) {
		#converts echo without args to print without args
		$leading_whitespace = $1;
		push @code, $leading_whitespace."print";
	} elsif ($line =~ /^(\s*)echo -n (.+)/) {
		#converts all other calls to echo -n to calls to print
		my ($leading_whitespace, $echo_to_print) = ($1, $2);
		convert_echo($leading_whitespace, $echo_to_print, 0);
	} elsif ($line =~ /^(\s*)echo (.+)/) {
		#converts all other calls to echo to calls to print
		my ($leading_whitespace, $echo_to_print) = ($1, $2);
		convert_echo($leading_whitespace, $echo_to_print, 1);
	} elsif ($line =~ /^(\s*)(chmod|cp|mv)( -.+)* (.+) (.+)/) {
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
} else {#		} elsif ($arg2 =~ /\$.+/) {
			$system_call = "['$cmd', '$options', $first_arg, $second_arg]" if $options;
			$system_call = "['$cmd', $first_arg, $second_arg]" if !$options;
#		} else {
#			$system_call = "['$cmd', '$options', '$first_arg', '$second_arg']" if $options;
#			$system_call = "['$cmd', '$first_arg', '$second_arg']" if !$options;
		}

		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(ls|rm|touch|sleep|mkdir|rmdir|unzip|gzip)( -.+)* (.+)/) {
		my ($leading_whitespace, $cmd, $options, $args) = ($1, $2, $3, $4);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option

                #handles the arguments "$*", $[@*], $[0-9]+ and $.+ separately
		my $arg = map_option_arg($args);

		#generates system call string
		if ($args =~ /\$[\@\*]/) {
			$system_call = "['$cmd', '$options'] + $arg" if $options;
			$system_call = "['$cmd'] + $arg" if !$options;
} else {#		} elsif ($args =~ /\$.+/) {
			$system_call = "['$cmd', '$options', $arg]" if $options;
			$system_call = "['$cmd', $arg]" if !$options;
#		} else {
#			$system_call = "['$cmd', '$options', '$arg']" if $options;
#			$system_call = "['$cmd', '$arg']" if !$options;
		}

		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(ls|pwd|id|date)( -.+)*/) {
		my ($leading_whitespace, $cmd, $options) = ($1, $2, $3);
		$options =~ s/ /', '/g if $options; #seperates options
		$options =~ s/^', '// if $options; #removes empty leading option
		$system_call = "['$cmd', '$options']" if $options;
		$system_call = "['$cmd']" if !$options;
		push @code, $leading_whitespace."subprocess.call($system_call)";
		import("subprocess");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=`expr (.+)`/) {
		#handles variable initialisation involving 'var=`expr .+`'
		my ($leading_whitespace, $variable, $shell_expression) = ($1, $2, $3);
		$python_expression = convert_variable_initialisation($shell_expression);
		push @code, $leading_whitespace."$variable = $python_expression";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$\(\((.+)\)\)/) {
		#handles variable initialisation involving 'var=$((.+))'
		my ($leading_whitespace, $variable, $shell_expression) = ($1, $2, $3);
		$python_expression = convert_variable_initialisation($shell_expression);
		push @code, $leading_whitespace."$variable = $python_expression";
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
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$([^ ]+)/) {
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
	} elsif ($line =~ /^(\s*)cd ([^ ]+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."os.chdir('$2')";
		import("os");
	} elsif ($line =~ /^(\s*)exit ([0-9]+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.exit($2)";
		import("sys");
	} elsif ($line =~ /^(\s*)read ([^ ]+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = sys.stdin.readline().rstrip()";
		import("sys");
	} elsif ($line =~ /^(\s*)for ([^ ]+) in \"\$\*\"/) {
		#handles for loops involving "$*"
		$leading_whitespace = $1;
		push @code, $leading_whitespace."for $2 in ' '.join(sys.argv[1:]):";
	} elsif ($line =~ /^(\s*)for ([^ ]+) in \"?\$[\@\*]/) {
		$leading_whitespace = $1;
		#handles for loops involving $[@*]
		push @code, $leading_whitespace."for $2 in sys.argv[1:]:";
	} elsif ($line =~ /^(\s*)for ([^ ]+) in ([^\?\*]+)/) {
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
	} elsif ($line =~ /^(\s*)for ([^ ]+) in (.+)/) {
		my ($leading_whitespace, $loop_variable, $file_type) = ($1, $2, $3);
		push @code, $leading_whitespace."for $loop_variable in sorted(glob.glob(\"$file_type\")):";
		import("glob");
	} elsif ($line =~ /^(\s*)while read ([^ ])/) {
		my ($leading_whitespace, $variable) = ($1, $2);
		push @code, $leading_whitespace."for $variable in sys.stdin:";
		import("sys");
	} elsif ($line =~ /^(\s*)(if|elif|while) (true|false)/) {
		#handles if/elif/while with negated true/false
		my ($leading_whitespace, $control, $cmd) = ($1, $2, $3);
		push @code, $leading_whitespace."$control not subprocess.call(['$cmd']):";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(if|elif|while) (diff|fgrep)( -.+)* (.+) (.+)/) {
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
	} elsif ($line =~ /^(\s*)(if|elif|while) test (.+)/) {
		#handles all other if/elif/while statements with test command
		my ($leading_whitespace, $control, $expression) = ($1, $2, $3);
		$python_expression = map_if_while($expression);
		$python_expression =~ s/ $//; #removes trailing space
		push @code, $leading_whitespace."$control $python_expression:";
	} elsif ($line =~ /^(\s*)(if|elif|while) \[ (.+) \]/) {
		#handles all other if/elif/while statements with [ ] notation
		my ($leading_whitespace, $control, $expression) = ($1, $2, $3);
		$python_expression = map_if_while($expression);
		$python_expression =~ s/ $//; #removes trailing space
		push @code, $leading_whitespace."$control $python_expression:";
	} elsif ($line =~ /^(\s*):/) {
		#matches empty statements
		$leading_whitespace = $1;
		push @code, $leading_whitespace."pass";
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
	if ($comment ne "") {
		$comments{$code[$#code]} = $comment;
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
unshift @code, "$interpreter" if $interpreter;
foreach $line (@code) {
	print "$line\n" if $line ne " ";
}

#prepends an import of the given package to the code if not already present
sub import {
	my $package = $_[0];
	unshift @code, "import $package" if !grep(/^import $package$/, @code);
}

#re-indents a given line of code based on the previous tab count
sub indent_code {
	my $line = $_[0];
	if ($line =~ /^(if|while|for)/) {
		$line = "$tab_count".$line; #copies line with current tab count
		$tab_count .= "\t"; #increments for next line/block
	} elsif ($line =~ /^(elif|else)/) {
		$tab_count =~ s/\t//; #decrements tab count temporarily
		$line = "$tab_count".$line; #copies line with decremented tab count
		$tab_count .= "\t"; #re-increments for next line/block
	} elsif ($line =~ /^(fi|done)/) {
		$tab_count =~ s/\t//; #decrements tab count at end of control structure
	} else {
		$line = "$tab_count".$line; #copies line with current tab count
	}
	return $line;
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

#converts variable initialisations involving var=`expr .+` and var=$((.+))
sub convert_variable_initialisation {
	my @shell_exp = split / /, $_[0];
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
	return $python_exp;
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
	while ($i <= $#words) {
		#filters out empty strings
		$i++ if $words[$i] =~ /^$/;
		last if $i > $#words;
		$words[$i] =~ s/'//g; #deals with ' chars later
		my $mapped_variable = map_special_variable($words[$i]);
		$string_to_print .= "$mapped_variable + " if $i < $#words;
		$string_to_print .= "$mapped_variable, " if $i == $#words && $word !~ /('+)$/;
		$string_to_print .= "$mapped_variable + " if $i == $#words && $word =~ /('+)$/ && $interpolate_variables == 1;
		$string_to_print .= "$mapped_variable, " if $i == $#words && $word =~ /('+)$/ && $interpolate_variables == 0;
		$i++;
	}

	
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
		#interpolates variables with double quotes
		$interpolate_variables = 1;
		$input = map_special_variable($1);
	} elsif ($input =~ /^('\$.+')$/) {
		#returns variables within single quotes
		$input =~ $1;
	} elsif ($input =~ /^\$/) {
		#interpolates other variables
		$input =~ s/^\$//;
		$interpolate_variables = 0;
		$input = map_special_variable($input);
	} elsif ($input =~ /^'.+'$/) {
		return $input; #returns original string
	} else {
		$input = "'$input'"; #returns quoted string
	}
	return $input;
}

#maps a shell file test to its python analogue
sub map_file_test {
	my ($test_operator, $file) = @_;
	import("os");

	$file = map_option_arg($file);

	#determines python command based on test operator
	if ($test_operator eq "-e") {
		return "os.path.exists($file)";
	} elsif ($test_operator =~ /([rwx])/) {
		my $rwx = $1;
		$rwx =~ tr/rwx/RWX/;
		return "os.access($file, os.$rwx"."_OK)";
	} elsif ($test_operator eq "-f") {
		return "os.path.isfile($file)"
	} elsif ($test_operator eq "-d") {
		return "os.path.isdir($file)";
	} elsif ($test_operator eq "-h") {
		return "os.path.islink($file)";
	}

}

#maps all if/elif and while statements to their python analogues
sub map_if_while {
	my $expression = $_[0];
	my @terms = split / /, $expression;
	my $python_expression = "";
	my $i = 0;

	#maps each term of the shell expression to its analogue in python
	while ($i <= $#terms) {
		#skips empty terms
		$i++ if $terms[$i] eq "";
		last if $i > $#terms;

		if ($terms[$i] eq "-a") {
			$python_expression .= "and";
		} elsif ($terms[$i] eq "-o") {
			$python_expression .= "or";
		} elsif ($terms[$i] =~ /^-(eq|ne|lt|le|gt|ge)$/) {
			#matches numeric comparisons
			$python_expression .= convert_operator($1);
		} elsif ($terms[$i] eq "=" || $terms[$i] eq "==") {
			#matches string comparisons
			$python_expression .= convert_operator($terms[$i]);
		} elsif ($terms[$i] =~ /^-[erwxfdh]$/) {
			#matches file test operators
			$python_expression .= map_file_test($terms[$i], $terms[++$i]);
		} elsif ($terms[$i] =~ /^\$/) {

			#maps special variables to their python analogues
			if ($terms[$i - 1] && $terms[$i - 1] =~ /=/) {
				$python_expression .= map_option_arg($terms[$i]);
			} elsif ($terms[$i + 1] && $terms[$i + 1] =~ /=/) {
				$python_expression .= map_option_arg($terms[$i]);
			} else {
				$python_expression .= "int(";
				$python_expression .= map_option_arg($terms[$i]);
				$python_expression .= ")";
			}

		} elsif ($terms[$i - 1] && $terms[$i - 1] =~ /=/) {
			$python_expression .= "'$terms[$i]'"; #maps strings
		} elsif ($terms[$i + 1] && $terms[$i + 1] =~ /=/) {
			$python_expression .= "'$terms[$i]'"; #maps strings
		} else {
			$python_expression .= "int($terms[$i])" #maps remaining terms as integers
		}
		$python_expression .= " ";
		$i++;
	}

	return $python_expression;
}
