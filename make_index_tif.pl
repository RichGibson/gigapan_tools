#!/usr/bin/perl

#make_index_tif.pl - look in the current directory for .tif images
#create directories small and preview, and put smaller versions of
#the .tif into those directories.
#also creates small/index.html, which is the index of those images.
#and creates file gigapan_info.txt which has the width and height of the 
#tifs. This uses gdal


$f = shift;
my @list;

# build a list of...

# first see if the gigapan_info.txt file exists. and read it in.
my %filelist;
if (-e 'gigapan_info.txt') {
	warn "reading gigapan_info.txt\n";
	open IN, "gigapan_info.txt" or die "can't read gigapan_info.txt $!\n";
	while (my $st = <IN>) {
		#name|date|x|y|[lat lng later]
		my ($name, $date, $x, $y) = split(/\|/, $st);
		$filelist{$name}->{date}=$date;
		$filelist{$name}->{x}=$x;
		$filelist{$name}->{y}=$y;
	}
	close IN;
	warn "done reading gigapan_info.txt\n";
}
open INFO, ">>gigapan_info.txt" or die "can't open $!\n";


# if we have a single file, put it on the list, otherwise, read all files and put on the lsit
if ( $f) {
	push @list, $f;
} else {
	opendir DIR, '.';
	#open OUT, "small/index.html";
	while (my $f = readdir DIR) {
		push @list, $f;
	}
}

# build/extend %filelist and make the preview and thumbnail images
foreach $f (sort @list) {
	next unless ($f =~ /\.tif(f)?$/);
	next if ($f =~ /^\._/);
	print "\nworking on $f\t";

	$fout = $f;
	$fout =~ s/tif(f)?$/png/;
	$filelist{$f}->{fout} = $fout;
	$filelist{$f}->{status} = make_small($f, $fout);
	print "\n";
	close OUT;
}

### write out the new index.html
if (! -e small) {
    `mkdir small`;
}
if (! -e preview) {
    `mkdir preview`;
}
open OUT, ">small/index.html";
print OUT "<ol>\n";
foreach my $f (sort keys %filelist) {
	print OUT qq(<li><a href="../preview/$filelist{$f}->$fout">$f</a> $filelist->{$f}->{status}\n);
}
print OUT "</ol>\n";

foreach my $f (sort keys %filelist) {
	
	print  $filelist{$f}->{fout} . "\n";
	print OUT qq(<li><a href="../preview/$filelist{$f}->{fout}"><img src="$filelist{$f}->{fout}"></a><br>$f $filelist->{$f}->{status}\n);
}
close OUT;

print "If everything worked see small/index.html for your index\n";


#change to the model of make_exif_header_descend, where it only does what is needed.
sub make_small {
	($f, $fout) = @_; 
	# don't overwrite existing images - this might be bogus when I want to overwrite a 'bad' image 
	# with a new one..

	# figure out size
	($x, $y) = get_size($f);


	# now I want the larger value to be $max pixels, and the smaller adjusted appropriately...
	# but screw it, I 'know' that x is almost always, maybe always, the controlling dimension.
	#...no, I have some high not wide images.

	# this works exactly as I wanted...but I wanted the wrong thing :-/  This makes images
	# up to 800 pixels high, which is too high to be practical.  fortunately most of my 
	# images are not vertical like calshot_p8...

	$max = 800;
	($new_x, $new_y) = make_xy($x, $y, $max);
	print "new_x = $new_x new_y=$new_y\t";
	$gp = $x * $y;
	$gp2 = sprintf("%04.1f", $gp / 1000000);	
	$gp3 = sprintf("%01.2f", $gp / 1000000000);	

	$status = "$gp2 megapixels, $gp3 gigapixels original ($x, $y) shrank to ($new_x, $new_y)"; 
	#$status = "$gp pixels, $gp2 megapixes, $gp3 gigapixels original ($x, $y) shrank to ($new_x, $new_y)"; 
 	if (-e "small/$fout") {
		$status .= "(small image not overwritten)";
	} else {
		print "calling gdal_translate -outsize $new_x $new_y -of PNG $f small/$fout\t";
		`gdal_translate -outsize $new_x $new_y -of PNG $f small/$fout`;
	}

	# make max like some reasonable value that is 'pretty big' but
	# not full size.
	if ($x > $y) {
		$max = $x;
	} else {
		$max = $y;
	}
	# so now max is the biger of x or y
	# now reduce it to something...
	# max = the greater of 5500 or 10% of max or?
	@t = sort( 5500, $max*.1);
	$max = pop @t;
	
	($new_x, $new_y) = make_xy($x, $y, $max);
 	if (-e "preview/$fout") {
		$status .= "(preview image not overwritten)";
	} else {
		print "calling gdal_translate -outsize $new_x $new_y -of PNG $f preview/$fout\t";
		`gdal_translate -outsize $new_x $new_y -of PNG $f preview/$fout`;
	}
	return $status;
}


sub make_xy {
        my @c = @_;

        # there is something clever here, that this line hints at.
        $p = ($c[1] <=> $c[0]);
        if ($p < 0) {
                $p = 0;
        }
        # set the lower number as its original value times the
        # ration between the new higher number and the original higher number
foreach (0..2) {
	#print "make_xy: \$c[$_] = $c[$_]\n";
}
	#print "make_xy: \$p = $p\n";
	eval {
        $c[1-$p] = int( $c[1-$p] * $c[2]/ $c[$p]);
	};
        $c[$p] = $c[2];
        return @c;
}

sub get_size {
	my $f = shift;
	
	my $x =$filelist{$f}->{x};
	my $y =$filelist{$f}->{y};
	$y =~ s/\n//;
	print "get_size() x=$x y=$y\t";
	return ($x, $y) if ($x && $y);

	$foo = `gdalinfo $f`;
	$foo =~ /Size is(.+)/;
	($x, $y) = split(/,/, $1);
	print "get_size() called gdalinfo  x=$x y=$y\t";
	$filelist{$f}->{x} = $x;
	$filelist{$f}->{y} = $y;
	print INFO "$f||$x|$y\n";
	return ($x, $y);
}

