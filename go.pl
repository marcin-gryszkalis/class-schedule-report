#!/usr/bin/perl
print `perl plan.pl`;

# pages for poster printing
$maxpages = 2;

$step = 0.06;
for (1..3)
{
    $n = "r$_";
 #next if $n eq 'r2';
    print "making $n\n";
    printf `latex $n.tex`;
    #printf
    `dvips -o $n.eps -E $n.dvi`;
    `epstopdf $n.eps`;

    #printf
    #`dvips -x 333 -y 333 -o ${n}_small.ps $n.dvi`;

    # ok for nauczyciele
    #printf
    #`dvips -x 555 -y 555 -o ${n}_med.ps $n.dvi`;


    #printf `poster -v -s1 -iA2 -mA4 -o ${n}_poster.ps $n.ps`;
    $s = 0.5;
    while (1)
    {
        $s += $step;
        print "poster p4: $n:$s\n";
        $t = `poster -v  -s${s}   -mA4 -o ${n}_poster.ps ${n}.eps 2>&1  | grep Deciding`;
        #$t = $t[0];
        #print join "#", @t;
        print "$t";
        die "poster printed sth strange" unless $t =~ m/Deciding for (\d+) columns? and (\d+) rows? of (portrait|landscape) pages/;
        $x = $1; $y = $2;
        $v = $x*$y;
        last if $v > $maxpages;
    }

    $s -= $step;
    print `poster -v  -s${s}   -mA4 -o ${n}_poster.ps ${n}.eps`;
}

printf `latex r4_0.tex`;
`dvips -o r4_0.ps r4_0.dvi`;

# hack to clean L/- L entries
open(my $fx, "r4_1.tex");
open(my $fy, ">r4_1x.tex");
while (<$fx>)
{
    s/\\X{L[^}]+}/\\X{}/g;
    print $fy $_;
}


unlink "r4_1.tex";
`cp "r4_1x.tex" "r4_1.tex"`;

printf `latex r4_1.tex`;
`dvips -o r4_1.ps r4_1.dvi`;

for (<*.ps>)
{
    `ps2pdf $_`;
}
