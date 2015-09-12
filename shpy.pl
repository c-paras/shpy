#!/usr/bin/perl -w

$interpreter = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(#.*)/) {
		push @code, "$1"; #copies start-of-line comments into python code
	} elsif ($line =~ /^(\s*)echo (.*)/) {
		#converts calls to echo to calls to print
		$leading_whitespace = $1;
		$echo_to_print = $2;
		convert_echo($leading_whitespace, $echo_to_print);
	} elsif ($line =~ /^(\s*)ls -([a-z]+) ?(.*)?/) {
		$leading_whitespace = $1;

		#handles optional arguments to ls -<options>
		if ($3 ne "") {

			#handles the case whether the argument is "$@"
			if ($3 eq '"$@"') {
				push @code, $leading_whitespace."subprocess.call(['ls', '-$2'] + sys.argv[1:])";
				import("sys");
			} else {
				push @code, $leading_whitespace."subprocess.call(['ls', '-$2', '$3'])";
			}

		} else {
			push @code, $leading_whitespace."subprocess.call(['ls', '-$2'])";
		}

		import("subprocess");
	} elsif ($line =~ /^(\s*)ls ?(.*)?/) {
		$leading_whitespace = $1;

		#handles optional arguments to ls
		if ($2 ne "") {
			push @code, $leading_whitespace."subprocess.call(['ls', '$2'])";
		} else {
			push @code, $leading_whitespace."subprocess.call('ls')";
		}

		import("subprocess");
	} elsif ($line =~ /^(\s*)pwd/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['pwd'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)id/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['id'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)date/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['date'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=`expr (.*)`/) {
		#handles variable initialisation involving 'var=`expr .*`'
		$leading_whitespace = $1;
		$variable = $2;
		@shell_exp = split / /, $3;

		#converts each expression from shell style to python style
		foreach $expression (@shell_exp) {
			if ($expression =~ /\$([0-9]+)/) {
				$python_exp .= "sys.argv[$1] "; #handles special vars
			} elsif ($expression =~ /\$(.*)/) {
				$python_exp .= "int($1) "; #handles variables
			} else {
				#copies arithmetic operators and numeric values
				$python_exp .= "$expression ";
			}
		}

		push @code, $leading_whitespace."$variable = $python_exp";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$([0-9]+)/) {
		#handles variable initialisation involving 'var=$[0-9]+'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = sys.argv[$3]";
		import("sys");
        } elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=\$(.*)/) {
                #handles variable initialisation involving 'var=$.*'
                $leading_whitespace = $1;
                push @code, $leading_whitespace."$2 = $3";
                import("sys");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=(.*)/) {
		#handles variable initialisation involving 'var=val'
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = '$3'";
	} elsif ($line =~ /^(\s*)cd (.*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."os.chdir('$2')";
		import("os");
	} elsif ($line =~ /^(\s*)exit ([0-9]*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.exit($2)";
		import("sys");
	} elsif ($line =~ /^(\s*)read (.*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = sys.stdin.readline().rstrip()";
		import("sys");
	} elsif ($line =~ /^for (.*) in \*\.(.*)/) {
		$loop_variable = $1;
		$file_type = $2;
		push @code, "for $loop_variable in sorted(glob.glob(\"*.$file_type\")):";
		import("glob");
	} elsif ($line =~ /^for (.*) in (.*)/) {
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
	} elsif ($line =~ /^if test -r (.*)/) {
		push @code, "if os.access('$1', os.R_OK):";
		import("os");
	} elsif ($line =~ /^if test -d (.*)/) {
		push @code, "if os.path.isdir('$1'):";
		import("os");
	} elsif ($line =~ /^if test (.*) = (.*)/) {
		push @code, "if '$1' == '$2':"; #handles simple if
	} elsif ($line =~ /^elif test (.*) = (.*)/) {
		push @code, "elif '$1' == '$2':"; #handles simple elif
	} elsif ($line =~ /^else$/) {
		push @code, "else:"; #translates 'else' into 'else:'
	} elsif ($line =~ /^while test \$(.*) -(.*) \$(.*)/) {
		$operator = convert_operator($2);
		push @code, "while int($1) $operator int($3):";
	} elsif ($line =~ /^\s*do\s*$/ || $line =~ /^\s*done\s*$/ || $line =~ /^\s*then\s*$/ || $line =~ /^\s*fi\s*$/) {
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
	$operator = $_[0];

	if ($operator eq "eq") {
		return "eq";
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

	@str = split / /, $echo_to_print;

	#removes $ from variables
	if ($str[0] =~ /\$([a-zA-Z_][a-zA-Z0-9_]*)/) {
		$string = "$1" if $1 ne "";
	} else {
		$string = "'$str[0]'" if $str[0] ne "";
	}

	#handles any remaining words on echo line
	shift @str;
	foreach $word (@str) {

		#removes $ from variables and formats words as <var> or '<var>'
		if ($word =~ /\$([0-9]+)/) {
			$string .= ", sys.argv[$1]" if $1 ne "";
			import("sys");
		} elsif ($word =~ /\$([a-zA-Z_][a-zA-Z0-9_]*)/) {
			$string .= ", $1" if $1 ne "";
		} else {
			$string .= ", '$word'" if $word ne "";
		}

	}

	push @code, $leading_whitespace."print $string";
}
