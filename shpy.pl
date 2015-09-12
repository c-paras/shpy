#!/usr/bin/perl -w

$interpreter = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(\s*)echo (.*)/) {
		$leading_whitespace = $1;
		$echo_to_print = $2;

		if ($echo_to_print =~ /^'/ && $echo_to_print =~ /'$/) {
			push @code, $leading_whitespace."print $echo_to_print";
			next;
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
	} elsif ($line =~ /^(\s*)ls -l ?(.*)?/) {
		$leading_whitespace = $1;

		#handles optional arguments to ls -l
		if ($2 ne "") {
			push @code, $leading_whitespace."subprocess.call(['ls', '-l', '$2'])";
		} else {
			push @code, $leading_whitespace."subprocess.call(['ls', '-l'])";
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
		push @code, "subprocess.call(['date'])";
		import("subprocess");
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=(.*)/) {
		#handles variable initialisation 'var=val'
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
				$loop .= "'$arg', "; #formats numeric values
			} else {
				$loop .= "$arg, "; #formats words
			}
		}

		$loop =~ s/, $/:/; #converts last instance of ", " to :
		push @code, "for $loop_variable in $loop";
	} elsif ($line =~ /^if test (.*) = (.*)/) {
		push @code, "if '$1' == '$2':";
	} elsif ($line =~ /^elif test (.*) = (.*)/) {
		push @code, "elif '$1' == '$2':";
	} elsif ($line =~ /^else/) {
		push @code, "else:";
	} elsif ($line =~ /^do/ || $line =~ /^done/ || $line =~ /^then/ || $line =~ /^fi/) {
		#prevents 'do', 'done', 'then' and 'fi' from being appended to python code
	} elsif ($line =~ /^(\s*)$/) {
		push @code, $1;
	} else {
		#turns all other lines into untranslated comments
		push @code, "#$line";
	}

}

unshift @code, "$interpreter" if $interpreter ne "";
print "$_\n" foreach @code;

#prepends an import of the given package if not already present
sub import {
	my $package = $_[0];
	unshift @code, "import $package" if !grep(/^import $package$/, @code);
}
