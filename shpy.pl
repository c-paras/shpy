#!/usr/bin/perl -w

$interpreter = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(\s*#.*)/) {
		push @code, "$1"; #copies start-of-line comments into python code
	} elsif ($line =~ /^(\s*)echo -n ?(["']["'])?\s*$/) {
		#converts echo -n without args to sys.stdout.write("")
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.stdout.write(\"\")";
		import("sys");
	} elsif ($line =~ /^(\s*)echo ?(["']["'])?\s*$/) {
		#converts echo without args to print without args
		$leading_whitespace = $1;
		push @code, $leading_whitespace."print";
	} elsif ($line =~ /^(\s*)echo (.+)/) {
		#converts all other calls to echo to calls to print
		my ($leading_whitespace, $echo_to_print) = ($1, $2);
		convert_echo($leading_whitespace, $echo_to_print);
	} elsif ($line =~ /^(\s*)ls -([a-z]+) (.+)/) {
		my ($leading_whitespace, $options) = ($1, $2);

		#determines whether the argument is "$[@*]"
		if ($3 =~ /\$[@*]/) {
			push @code, $leading_whitespace."subprocess.call(['ls', '-$options'] + sys.argv[1:])";
			import("sys");
		} else {
			push @code, $leading_whitespace."subprocess.call(['ls', '-$options', '$3'])";
		}

		import("subprocess");
	} elsif ($line =~ /^(\s*)ls -([a-z]+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['ls', '-$2'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)ls (.+)/) {
		my ($leading_whitespace, $arg) = ($1, $2);

		#determines whether the argument is "$[@*]"
		if ($arg =~ /\$[@*]/) {
			push @code, $leading_whitespace."subprocess.call(['ls'] + sys.argv[1:])";
			import("sys");
		} else {
			push @code, $leading_whitespace."subprocess.call(['ls', '$arg'])";
		}

		import("subprocess");
	} elsif ($line =~ /^(\s*)chmod ([0-7]{1,3}) (.*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['chmod', '$2', '$3'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(mv|cp) (.+) (.+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['$2', '$3', '$4'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)rm (.+)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['rm', '$2'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)(ls|pwd|id|date)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['$2'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=`expr (.+)`/) {
		#handles variable initialisation involving 'var=`expr .*`'
		my ($leading_whitespace, $variable) = ($1, $2);
		@shell_exp = split / /, $3;

		#converts each expression from shell style to python style
		foreach $expression (@shell_exp) {
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
		#handles variable initialisation involving 'var=$.*'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = $3";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=(.+)/) {
		#handles variable initialisation involving 'var=val'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = '$3'";
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
	} elsif ($line =~ /^for (.+) in ([^\?\*]+)/) {
		$loop_variable = $1;
		@args = split / /, $2;

		#appends each arg to loop in the format '<arg>' or <arg>
		foreach $arg (@args) {
			if ($arg !~ /[0-9]+/) {
				$loop_args .= "'$arg', "; #formats numeric values
			} else {
				$loop_args .= "$arg, "; #formats words
			}
		}

		$loop_args =~ s/, $/:/; #converts last instance of ", " to :
		push @code, "for $loop_variable in $loop_args";
	} elsif ($line =~ /^for (.+) in (.+)/) {
		my ($loop_variable, $file_type) = ($1, $2);
		push @code, "for $loop_variable in sorted(glob.glob(\"$file_type\")):";
		import("glob");
	} elsif ($line =~ /^(if|elif|while) test -e (.+)/) {
		push @code, "$1 os.path.exists('$2')";
		import("os");
	} elsif ($line =~ /^(if|elif|while) test -([rwx]) (.+)/) {
		$rwx = $2;
		$rwx =~ tr/rwx/RWX/;
		push @code, "$1 os.access('$3', os.$rwx"."_OK):";
		import("os");
	} elsif ($line =~ /^(if|elif|while) test -f (.+)/) {
		push @code, "$1 os.path.isfile('$2')";
		import("os");
	} elsif ($line =~ /^(if|elif|while) test -d (.+)/) {
		push @code, "$1 os.path.isdir('$2'):";
		import("os");
	} elsif ($line =~ /^(if|elif|while) test -h (.+)/) {
		push @code, "$1 os.path.islink('$2')";
		import("os");
	} elsif ($line =~ /^(if|elif|while) test \$(.+) -?(.+) \$(.+)/) {
		#handles if's, elif's and while's involving variable interpolation
		my ($control, $first, $shell_operator, $second) = ($1, $2, $3, $4);
		$operator = convert_operator($shell_operator);
		push @code, "$control $first $operator $second:" if $shell_operator =~ /=/;
		push @code, "$control int($first) $operator int($second):" if $shell_operator !~ /=/;
	} elsif ($line =~ /^(if|elif|while) test (.+) -?(.+) (.+)/) {
		#handles if's, elif's and while's not involving variable interpolation
		my($control, $first, $shell_operator, $second) = ($1, $2, $3, $4);
		$operator = convert_operator($shell_operator);
		push @code, "$control '$first' $operator '$second':" if $shell_operator =~ /=/;
		push @code, "$control int($first) $operator int($second):" if $shell_operator !~ /=/;
	} elsif ($line =~ /^else$/) {
		push @code, "else:"; #translates 'else' into 'else:'
	} elsif ($line =~ /^\s*(do|done|then|fi)\s*$/) {
		#prevents 'do', 'done', 'then' and 'fi' from being appended to code
	} elsif ($line =~ /^\s*$/) {
		push @code, $line; #copies blank and whitespace lines into python code
	} else {
		#converts all other lines into untranslated comments
		push @code, "#$line [untranslated code]";
	}

}

unshift @code, "$interpreter" if $interpreter ne "";
print "$_\n" foreach @code;

#prepends an import of the given package to the code if not already present
sub import {
	my $package = $_[0];
	unshift @code, "import $package" if !grep(/^import $package$/, @code);
}

#converts numeric test operators to python style
sub convert_operator {
	my $operator = $_[0];

	if ($operator eq "eq") {
		return "eq";
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
	my ($leading_whitespace, $echo_to_print) = @_;

	#removes double quotes from either side of string if applicable
	$echo_to_print =~ s/^"//;
	$echo_to_print =~ s/"$//;

	#handles case where entire string passed to echo is within single quotes
	if ($echo_to_print =~ /^'/ && $echo_to_print =~ /'$/) {
		push @code, $leading_whitespace."print $echo_to_print";
		return;
	}

	my @words = split / /, $echo_to_print;
	my $string_to_print = "";
	my $i = 0;

	#handles each 'word' on echo line
	do {

		#removes $ from variables and formats words as <var> or '<var>'
		if ($words[$i] =~ /\$([0-9]+)/) {
			$string_to_print .= "sys.argv[$1], " if $1 ne "";
			import("sys");
		} elsif ($words[$i] =~ /\$[@*]/) {
			$string_to_print .= "sys.arg[1:], ";
			import("sys");
		} elsif ($words[$i] =~ /\$#/) {
			$string_to_print .= "len(sys.argv) - 1, ";
			import("sys");
		} elsif ($words[$i] =~ /\$([a-zA-Z_][a-zA-Z0-9_]*)/) {
			$string_to_print .= "$1, " if $1 ne "";
		} else {
			$string_to_print .= "'$words[$i]', " if $words[$i] ne "";
		}

		$i++;
	} while ($i <= $#words);

	$string_to_print =~ s/, $//; #removes trailing ', '
	push @code, $leading_whitespace."print $string_to_print";
}
