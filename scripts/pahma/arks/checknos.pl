use strict;

my %chars;
my %patterns;

while (<>) {
    # parse input line, clean up a bit
    chomp;
    #s/ +$//;
    #s/ +\t/\t/;
    my ($sortNum, $original) = split /\t/;
    $_ = $original;

    # make pattern from input
    s/\d+/9/g;
    s/[A-Z]+/A/g;
    s/[a-z]+/a/g;
    my $pattern = $_;
    $patterns{$pattern}++;

    my @chars = split '', $original;
    foreach my $c (@chars) {
        $chars{$c}++;
    }

    # generate ARK suffix
    my $ARK;
    my ($ARK, $left, $right, $extra);

    # keep periods by encoding them as x's
    my $o2 = $original;
    $o2 =~ s/\./X/g;

    # make letters upper case. why not? (strictly speaking not reversible, but we need to avoid lowercase L, etc.)
    $o2 =~ tr/a-z/A-Z/;

    # basic pattern
    my ($left, $right, $extra1, $extra2) = $o2 =~ /^([\d\w]+)\-(\d+)(\w*)\b(.*)$/;
    my $extra = $extra1 . $extra2;
    #$extra =~ s/^[\s\_\-\.\;\:\,\+\/\#]+//; # remove initial non-filing chars (i.e. punctuation)
    #                                        # NB: this may be problematic in some cases.

    if ($left && $right) {
        $ARK = sprintf "%2s%6s", ($left, $right, $extra);
        $ARK =~ s/ /0/g;
        $ARK .= $extra;
    }
    else { # fallback : see prose above
        $ARK = 'noARK';
    }

    # reverse the "arkification"
    my $unARK = $ARK;
    $unARK =~ s/X/./g;
    my ($left, $right, $extra) = $unARK =~ /^(.{2})(.{6})(.*)/;
    $left =~ s/^0+//;
    $right =~ s/^0+//;
    $unARK = $left . '-' . $right . $extra;

    # check if the reverse worked...
    my $uc_original = $original;
    $uc_original =~ tr/a-z/A-Z/;
    my $reversible = $unARK eq $uc_original ? '' : 'not reversible';

    #print "$left x $right x $extra\n";
    #print "$unARK eq $ARK\n";
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", ($ARK, $original, $pattern, $sortNum, $unARK, $uc_original, $reversible);
}

print STDERR "\ncharacters\n";
foreach my $char (sort { $chars{$b} <=> $chars{$a} } keys %chars) {
    printf STDERR "%s\t%s\n", ($char, $chars{$char})
}

print STDERR "\npatterns\n";
foreach my $pattern (sort { $patterns{$b} <=> $patterns{$a} } keys %patterns) {
    printf STDERR "%s\t%s\n", ($pattern, $patterns{$pattern})
}