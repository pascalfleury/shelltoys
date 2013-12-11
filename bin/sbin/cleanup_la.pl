#!/usr/bin/perl
use strict;

# These must be abspaths
if ( @ARGV ) {
    foreach my $la_file ( @ARGV ) {
	check_la($la_file) || print $la_file;
    }
} else {
    while ( my $in=<STDIN> ) {
	check_la($in) || print $in;
    }
}


sub check_la {
    my ($la_file) = @_;

    # Find out the .so name
    open(LA,$la_file) || die "Could not read '$la_file' !!!";
    my $line = grep { /dlname/o } <LA>;
    my ($libname) = $line=~/dlname=\'([^\']*)\'.*/o;
    close(LA);

    # Find out if the lib exists
    my $soname = `dirname $la_file` . "/" . $libname;
    return -f $soname;
}
