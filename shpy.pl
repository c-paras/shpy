#!/usr/bin/perl -w

$interpreter = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /^(\s*)echo (.*)/) {
		$leading_whitespace = $1;
		@str = split / /, $2;

		#removes $ from variables
		if ($str[0] =~ /\$([a-zA-Z_][a-zA-Z0-9_]*)/) {
			$string = "$1" if $1 ne "";
		} else {
			$string = "'$str[0]'" if $str[0] ne "";
		}

		#handles any remaining words on echo line
		shift @str;
		foreach $word (@str) {

			#removes $ from variables
			if ($word =~ /\$([a-zA-Z_][a-zA-Z0-9_]*)/) {
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

	} elsif ($line =~ /^(\s*)ls ?(.*)?/) {
		$leading_whitespace = $1;

		#handles optional arguments to ls
		if ($2 ne "") {
			push @code, $leading_whitespace."subprocess.call(['ls', '$2'])";
		} else {
			push @code, $leading_whitespace."subprocess.call('ls')";
		}

	} elsif ($line =~ /^(\s*)pwd/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['pwd'])";
	} elsif ($line =~ /^(\s*)id/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."subprocess.call(['id'])";
	} elsif ($line =~ /^(\s*)date/) {
		$leading_whitespace = $1;
		push @code, "subprocess.call(['date'])";
	} elsif ($line =~ /^(\s*)([a-zA-Z_][a-zA-Z0-9_]*)=(.*)/) { #variable initialisation
		$leading_whitespace = $1;
		push @code, $leading_whitespace."$2 = '$3'";
	} elsif ($line =~ /^(\s*)cd (.*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."os.chdir('$2')";
	} elsif ($line =~ /^(\s*)exit ([0-9]*)/) {
		$leading_whitespace = $1;
		push @code, $leading_whitespace."sys.exit($2)";
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
	} elsif ($line =~ /^do/ || $line =~ /^done/) {
		#prevents 'do' and 'done' from being appended to python code
	} else {
		#turns all other lines into untranslated comments
		push @code, "#$line";
	}

}

unshift @code, "import subprocess" if grep(/^subprocess.call\(/, @code);
unshift @code, "import os" if grep(/^os.chdir\(/, @code);
unshift @code, "import sys" if grep(/^sys./, @code);
unshift @code, "$interpreter" if $interpreter ne "";
print "$_\n" foreach @code;
