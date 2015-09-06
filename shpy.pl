#!/usr/bin/perl -w

while ($line = <>) {

	chomp $line;
	if ($line =~ /^#!/ && $. == 1) {
		print "#!/usr/bin/python2.7 -u\n";
	} elsif ($line =~ /echo/) {
		print "print 'hello world'\n";
	} else {
		#turn all other lines into untranslated comments
		print "#$line\n";
	}

}
