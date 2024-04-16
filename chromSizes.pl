my $file = shift;

open F, "zcat $file |";

my $length = 0;
while (<F>){
    if (/^>(\S+)/){
	my $chr = $1;
	if ($length > 0){
	    print "$length\n";
	}
	$length = 0;
	print "$chr\t";
    } else{
	chomp;
	$length += length($_);
    }
}

if ($length > 0){
    print "$length\n";
}
