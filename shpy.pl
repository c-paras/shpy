#!/usr/bin/perl -w

$interpreter = "";

#reads input shell source code from file(s) or from stdin
while ($line = <>) {
	chomp $line;

	if ($line =~ /^#!/ && $. == 1) {
		$interpreter = "#!/usr/bin/python2.7 -u";
	} elsif ($line =~ /echo (.*)/) {
		@str = split / /, $1;

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

		push @code, "print $string";
	} elsif ($line =~ /ls -l ?(.*)?/) {

		#handles optional arguments to ls -l
		if ($1 ne "") {
			push @code, "subprocess.call(['ls', '-l', '$1'])";
		} else {
			push @code, "subprocess.call(['ls', '-l'])";
		}

	} elsif ($line =~ /ls ?(.*)?/) {

		#handles optional arguments to ls
		if ($1 ne "") {
			push @code, "subprocess.call(['ls', '$1'])";
		} else {
			push @code, "subprocess.call('ls')";
		}

	} elsif ($line =~ /pwd/) {
		push @code, "subprocess.call(['pwd'])";
	} elsif ($line =~ /id/) {
		push @code, "subprocess.call(['id'])";
	} elsif ($line =~ /date/) {
		push @code, "subprocess.call(['date'])";
	} elsif ($line =~ /([a-zA-Z_][a-zA-Z0-9_]*)=(.*)/) {
		push @code, "$1 = '$2'";
	} else {
		#turns all other lines into untranslated comments
		push @code, "#$line";
	}

}

unshift @code, "import subprocess" if grep(/^subprocess.call\(/, @code);
unshift @code, "$interpreter" if $interpreter ne "";
print "$_\n" foreach @code;
