#!/usr/bin/perl -w
use utf8;
use locale;

use strict;
no strict 'refs';

use POSIX qw(locale_h);    # linia potrzebna przy trzeciej linii
setlocale(LC_ALL,"pl_PL.utf8");
setlocale(LC_CTYPE,"pl_PL.utf8");
setlocale(LC_COLLATE,"pl_PL.utf8");

use Data::Dumper;
use Devel::StackTrace;

# binmode STDOUT, ":utf8";
# print "zażółć gęślą jaźń\n";
# print uc "zażółć gęślą jaźń\n";
# print lc uc "zażółć gęślą jaźń\n";
#exit;

#use POSIX qw(setlocale);
#setlocale(&POSIX::LC_ALL,"pl");  # drugi argument w zaleznosci od systemu
my $plantxt = "plan.txt";

my $DEBUG=1;
my $VDEBUG=exists $ARGV[0] ? 1 : 0;

my $YEAR="2015/2016";

my $dynroom = 4000;

my $hours_start = 1;
my $hours_end = 8;

print STDERR "### parse ini\n" if $DEBUG;
open(D, "dic.txt") or die "cannot open dic.txt: $!";
my $ini;
my $mode = "";
while(<D>)
{
    chomp;
    next if (/^\s*$/);
    next if (/^#/);

    if (/^\[(.*)\]/)
    {
        $mode = $1;
        print STDERR "# mode=$mode\n" if $DEBUG;
        next;
    }


    if (/^(\S+)\s+(.*)/)
    {
        $ini->{$mode}->{$1} = $2;
    }
}
close(D);

print STDERR Dumper $ini if $VDEBUG;

sub namei($)
{
    my $t = shift;
    my $imie = $t->{imie};
    my $nazwisko  = $t->{nazwisko};
    $imie =~ s/^(.).*/uc($1)/ge;
    $imie .= '.';
    return "$imie $nazwisko";
}

sub fgodz($)
{
    $_ = shift;
    if (/(\d\d):(\d\d)\s+-\s+(\d\d):(\d\d)/)
    {
        return "$1\\raisebox{0.5em}{\\scriptsize $2} -- $3\\raisebox{0.5em}{\\scriptsize $4}";
    }


  my $trace = Devel::StackTrace->new;
  print $trace->as_string;

    die "strange fgodz ($_)";
}

my %rom = (
    0 => '0',
    1 => 'I',
    2 => 'II',
    3 => 'III',
    4 => 'IV',
    5 => 'V',
    6 => 'VI',
);

sub fklasa($)
{
    my $k = shift;
    my ($k1, $k2) = split//, $k, 2;

    # special mode for lo (lo after gimnazjum)
    if ($k2 eq 'lo') { $k1 -= 3; } # 4lo = 1lo
    # rzymskie: return $rom{$k1}.'{\small '.uc($k2).'}';
    return $k1.'{\small '.uc($k2).'}';
}

sub klasafix($)
{
    my $k = shift;
    my ($k1, $k2) = split//, $k, 2;

    # special mode for lo (lo after gimnazjum)
    if ($k2 eq 'lo') { $k1 += 3; } # 4lo = 1lo
    return $k1.$k2;
}

sub klasaunfix($)
{
    my $k = shift;
    my ($k1, $k2) = split//, $k, 2;

    # special mode for lo (lo after gimnazjum)
    if ($k2 eq 'lo') { $k1 -= 3; } # 4lo = 1lo
    return $k1.$k2;
}

sub fklasa_footnotesize($)
{
    my $k = fklasa(shift);
    $k =~ s/small/footnotesize/;
    return $k;
}

my %fx = (
    G => '\raisebox{0.5em}{\scriptsize\bfseries D}',
    P => '\raisebox{0.5em}{\scriptsize\bfseries R}',
    B => '\raisebox{0.5em}{\scriptsize\bfseries N}',
    );

# my $footer = "\\endtable\n\n$fx{G}  zażółć gęślą jaźń $fx{P}  zażółć gęślą jaźń $fx{B}  ZAŻÓŁĆ GĘŚLĄ JAŹŃ";
my $footer = "\\endtable\n\n~ ~ ";

print STDERR "### parse plan\n" if $DEBUG;
open(P, $plantxt) or die "cannot open plan.txt: $!";
my %defaults;
my ($imie, $nazwisko);
my $weekday;

my (%wychowawcy, %teachers, %klasy);

my %dnitygodnia = (
    p => 1,
    w => 2,
    s => 3,
    c => 4,
    t => 5,
);

my %hscale = (
    p => 10,
    w => 20,
    s => 30,
    c => 40,
    t => 50,
);

my $uid = 0;
my $hrs;
# hrs->{11}->{4b}->{ sala=>205 flaga=>X przedmiot=>mat nauczyciel=>Gryszkalis }
# hrs->{11}->{4b}->{C|D}->{ sala=>205 flaga=>X przedmiot=>mat nauczyciel=>Gryszkalis }
my $kls;
# kls->{4b}->{11}->...
my $tcr;
# tcr->{nn}->{11}->...
my $room;
# room->{000}->{11}->...
while(<P>)
{
    $uid++;

    chomp;
    next if (/^\s*$/);
    next if (/^#/);

    if (/^\[(.*)\]/) # teacher line, defaults
    {
        my @a = split /\s+/, $1;
        $imie = shift @a;
        $nazwisko = shift @a;
        print STDERR "## prsn=$nazwisko\n" if $DEBUG;
        %defaults = ();
        foreach (@a)
        {
            if (/^(\d+)$/) { $defaults{sala} = $1; }
            if (/^([A-Z])$/) { $defaults{flaga}->{$1} = 1; }
            if (/^([a-z]+)$/) { $defaults{przedmiot} = $1; }
            if (/^(\d[a-z]+)$/) { $defaults{klasa} = klasafix($1); }
        }
        print STDERR "## defaults=",Dumper \%defaults,"\n" if $DEBUG;

        my %tdata = (
            imie => $imie,
            nazwisko => $nazwisko,
            imie_nazwisko => "$imie $nazwisko",
        );
        $teachers{"$nazwisko $imie"} = \%tdata;
        next;
    }

    if (/^([pwsct])\s*$/) # weekday line
    {
        $weekday = $1;
        print STDERR "# day=$ini->{dnitygodnia}->{$dnitygodnia{$weekday}}\n" if $DEBUG;
    }

    if (/^(\d)(\s+(.*))?/)
    {
        my $h = $1;

        print STDERR "# h=$h\n" if $DEBUG;

        # merge defaults with current into %v
        my %v = %defaults;
        $v{nauczyciel} = "$nazwisko $imie";

        my %c;
        if ($3)
        {
            my @a = split /\s+/, $3;

            foreach (@a)
            {
                if (/^(\d+)$/) { $c{sala} = $1; }
                if (/^([a-z]+)$/) { $c{przedmiot} = $1; }
                if (/^(\d[a-z]+)$/) { $c{klasa} = klasafix($1); }
                if (/^([A-Z])$/) { $c{flaga}->{$1} = 1; }
            }


            $v{sala} = $c{sala} if ($c{sala});
            $v{przedmiot} = $c{przedmiot} if ($c{przedmiot});
            $v{klasa} = $c{klasa} if ($c{klasa});

            $v{flaga} = undef;
            foreach (keys %{$defaults{flaga}})
            {
                next if (($_ eq "C" || $_ eq "D") && ref $c{flaga} && $c{flaga}->{A}); # A just disables C and D
                $v{flaga}->{$_} = 1;
            }

            if (ref $c{flaga})
            {
                foreach (keys %{$c{flaga}})
                {
                    $v{flaga}->{$_} = 1;
                }
            }
        }
        else
        {
            $v{flaga} = undef;
            foreach (keys %{$defaults{flaga}})
            {
                $v{flaga}->{$_} = 1;
            }

        }

        $klasy{$v{klasa}} = fklasa($v{klasa}) unless ($v{klasa} eq "9x");

        # check for wychowawcy
        if ($v{przedmiot} eq "w" || $v{przedmiot} eq "kz" || $v{przedmiot} eq "ew")
        {
            $wychowawcy{$v{klasa}} = $v{nauczyciel};
        }

        # local hash
        $v{sala} = $ini->{klasa_sala}->{klasaunfix($v{klasa})} unless defined $v{sala};
        my %hv = (
            sala => $v{sala},
            przedmiot => $v{przedmiot},
            nauczyciel => $v{nauczyciel},
            godzina => $hscale{$weekday} + $h,
            klasa => $v{klasa},
        );

        if (ref $v{flaga})
        {
            for (keys %{$v{flaga}})
            {
                $hv{flaga}->{$_} = 1;
            }
        }

        if ($v{klasa} eq "9x") # klasa bez klasy
        {
            if ($v{przedmiot} eq 'l')  # liceum
            { 
                $v{sala} = $dynroom++; 
                $hv{sala} = $dynroom++; 
            }
            die "OVER1 $v{nauczyciel} $hscale{$weekday} + $h" if exists $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h};
            $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h} = \%hv;
            die "OVER2 $v{sala} $hscale{$weekday} + $h" if exists $room->{$v{sala}}->{$hscale{$weekday} + $h};
            $room->{$v{sala}}->{$hscale{$weekday} + $h} = \%hv;
            next;
        }

        my $splt = "";
        $splt = "C" if exists $v{flaga}->{C};
        $splt = "D" if exists $v{flaga}->{D};
        $splt = "X" if exists $v{flaga}->{X};
        $splt = "W" if exists $v{flaga}->{W};

        unless ($splt) # no split
        {
            die "OVER3 $hscale{$weekday} + $h $v{przedmiot} $v{klasa} $v{sala} $v{nauczyciel} [ ".Dumper($hrs->{$hscale{$weekday} + $h}->{$v{klasa}})." ] ".Dumper(\%hv) if exists $hrs->{$hscale{$weekday} + $h}->{$v{klasa}};
            $hrs->{$hscale{$weekday} + $h}->{$v{klasa}} = \%hv;
            die "OVER4 $v{klasa} $hscale{$weekday} + $h $v{przedmiot} $v{klasa} $v{sala} $v{nauczyciel} ".Dumper(\%hv) if exists $kls->{$v{klasa}}->{$hscale{$weekday} + $h};
            $kls->{$v{klasa}}->{$hscale{$weekday} + $h} = \%hv;
            die "OVER5 $v{nauczyciel} $hscale{$weekday} + $h $v{klasa} $v{nauczyciel} ".Dumper(\%hv) if exists $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h};
            $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h} = \%hv;
            die "OVER6 $v{sala} $hscale{$weekday} + $h $v{klasa} $v{nauczyciel} [ ".Dumper($room->{$v{sala}}->{$hscale{$weekday} + $h}) . " ]\n " if exists $room->{$v{sala}}->{$hscale{$weekday} + $h};
            $room->{$v{sala}}->{$hscale{$weekday} + $h} = \%hv;
        }
        else # split for C D W
        {
            die "OVER7 $hscale{$weekday} + $h $v{klasa} $splt [ ".Dumper($hrs->{$hscale{$weekday} + $h}->{$v{klasa}}->{$splt})." ]".Dumper(\%hv) if exists $hrs->{$hscale{$weekday} + $h}->{$v{klasa}}->{$splt};
            $hrs->{$hscale{$weekday} + $h}->{$v{klasa}}->{$splt} = \%hv;
            die "OVER8 $v{nauczyciel} $hscale{$weekday} + $h join:$uid" if exists $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h}->{"join:$uid"};
            $tcr->{$v{nauczyciel}}->{$hscale{$weekday} + $h}->{"join:$uid"} = \%hv;
            
            #die "OVER9 $v{sala} $hscale{$weekday} + $h join:$uid $v{klasa} $v{nauczyciel} ".Dumper(\%hv) unless exists $room->{$v{sala}}->{$hscale{$weekday} + $h}->{"join:$uid"};
            $room->{$v{sala}}->{$hscale{$weekday} + $h}->{"join:$uid"} = \%hv;
            if ($splt eq "W")
            {
                $kls->{$v{klasa}}->{$hscale{$weekday} + $h} = \%hv;
            }
            else
            {
                $kls->{$v{klasa}}->{$hscale{$weekday} + $h}->{$splt} = \%hv;
            }

        }

    }

}
close(P);

print STDERR Dumper $hrs if $VDEBUG;
print STDERR Dumper $kls if $VDEBUG;
print STDERR Dumper $tcr if $VDEBUG;
print STDERR Dumper $room if $VDEBUG;
print STDERR Dumper \%wychowawcy if $VDEBUG;
print STDERR Dumper \%teachers if $VDEBUG;


my $klasy_no = scalar keys %klasy;
print STDERR "# klasy: $klasy_no\n";

my $teachers_no = scalar keys %teachers;
print STDERR "# nauczyciele: $teachers_no\n";


# my $rooms_no = scalar keys %{$room};
my $rooms_no = 0;
foreach (sort { $a <=> $b } keys %{$room})
{
    next if $_ >= 1000;
    $rooms_no++;
}


print STDERR "# sale: $rooms_no\n";

#################################
# report 1
# teachers/hours
print STDERR "### R1\n" if $DEBUG;
open(R, ">r1.tex");
open(H, "header.tex.txt"); while (<H>) { print R $_; }; close(H);

print R '\=', "\n";
print R '\B!=2cm ! ! ! @'.($klasy_no*2-1).' \center{\Huge\sffamily\bfseries K~L~A~S~Y} " \center{\Large\bfseries '.$YEAR.'} \E!', "\n";
print R '\B!- ! ! ! @'.($klasy_no*2).' \= \E!', "\n";
print R '\B!=0.8cm ! ! ';
foreach (sort keys %klasy)
{
    print R '! @2 \center{\Large ', $klasy{$_},' ~ ~ ~ ', $ini->{klasa_sala}->{klasaunfix($_)}, '} ';
}
print R '\E!', "\n";

print R '\B!=0.5cm \Y{\begin{sideways} ~ ~ ~ ~ ~ Dni tygodnia\end{sideways}} ! \X{\begin{sideways} ~ ~ ~ ~ ~ ~ ~ Godzina lekcyjna\end{sideways}} ! Czas trwania ';
foreach (sort keys %klasy)
{
    my $wych = $wychowawcy{$_} ? namei($teachers{$wychowawcy{$_}}) : "nieznany";
    print R '! @2 \center{', $wych, '} ';
}
print R '\E!', "\n";
print R '\=', "\n";

for my $d (1..5)
{
    for my $h ($hours_start..$hours_end) # (0..9)
    {

        print R '\B!=1cm ';
        print(R '\X{\begin{sideways}\Large ', $ini->{dnitygodnia}->{$d}, '\end{sideways}} ') if $h == 4;

        print R " ! $h. ";
        print R " ! ", fgodz($ini->{godziny}->{$h}), " ! ";

        my $k = 0;
        foreach (sort keys %{$kls})
        {
            $k++;

            my $x = $kls->{$_}->{$d * 10 + $h};

            my $s = "";
            my $p = "";
            my $f = "";

            if ($x)
            {
                if (exists $x->{D} and not exists $x->{C})
                {
                    $s = $x->{D}->{sala};
                    $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};

                    $s = '\X{'.$s.'\\\\---}';

                    $p = $x->{D}->{przedmiot};
                    $p = $ini->{przedmioty}->{$p};

                    if (ref $x->{D}->{flaga})
                    {
                        foreach (keys %{$x->{D}->{flaga}}) { $f .= $fx{$_} if m/[PBG]/ }
                    }
                    $p = '\X{'.$p.$f.'\\\\---}';
                }
                elsif (exists $x->{C} and not exists $x->{D})
                {
                    $s = $x->{C}->{sala};
                    $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};

                    $s = '\X{---\\\\{}'.$s.'}';

                    $p = $x->{C}->{przedmiot};
                    $p = $ini->{przedmioty}->{$p};

                    if (ref $x->{C}->{flaga})
                    {
                        foreach (keys %{$x->{C}->{flaga}}) { $f .= $fx{$_} if m/[PBG]/ }
                    }

                    $p = '\X{---\\\\{}'.$p.$f.'}';
                }
                elsif (exists $x->{C} and exists $x->{D})
                {
                    my $s1 = $x->{D}->{sala};
                    $s1 = $ini->{sale}->{$s1} if exists $ini->{sale}->{$s1};
                    my $s2 = $x->{C}->{sala};
                    $s2 = $ini->{sale}->{$s2} if exists $ini->{sale}->{$s2};

                    $s = '\X{'.$s1.'\\\\{}'.$s2.'}';

                    my $p1 = $x->{D}->{przedmiot};
                    $p1 = $ini->{przedmioty}->{$p1};
                    my $p2 = $x->{C}->{przedmiot};
                    $p2 = $ini->{przedmioty}->{$p2};

                    my $f1 = "";
                    my $f2 = "";
                    if (ref $x->{C}->{flaga})
                    {
                        foreach (keys %{$x->{C}->{flaga}}) { $f .= $fx{$_} if m/[PBG]/ }
                    }

                    if (ref $x->{D}->{flaga})
                    {
                        foreach (keys %{$x->{D}->{flaga}}) { $f .= $fx{$_} if m/[PBG]/ }
                    }

                    $p = '\X{'.$p1.$f1.'\\\\{}'.$p2.$f2.'}';
                }
                else
                {
                    $s = $x->{sala} // "BEZSALI";
                    $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};

                    $p = $x->{przedmiot};

                    if (ref $x->{flaga})
                    {
                        foreach (keys %{$x->{flaga}}) { $f .= $fx{$_} if m/[PBG]/ }
                    }

                    print STDERR "No Mapping ($p)\n" unless  exists $ini->{przedmioty}->{$p};
                    $p = $ini->{przedmioty}->{$p};
                    $p .= $f;
                }
            }

            print R "$s | $p ";
            print R " ! " if ($k < $klasy_no);
        }

        print R '\E!', "\n";
        if ($h < $hours_end)
        {
            print R '\B!- | @'.($klasy_no*2+2).' \- \E!', "\n" ;
        }
        else
        {
            print R '\=', "\n" ;
        }

    }
}

print R '\=', "\n";

print R $footer;
open(H, "footer.tex.txt"); while (<H>) { print R $_; }; close(H);
close(R);



#################################
# report 2
# teachers/hours
print STDERR "### R2\n" if $DEBUG;
open(R, ">r2.tex");
open(H, "header.tex.txt"); while (<H>) { print R $_; }; close(H);

print R '\=', "\n";
print R '\B!=2cm ! ! ! @'.($teachers_no-3).' \center{\Huge\sffamily\bfseries N A U C Z Y C I E L E}  " @3 \center{\Large\bfseries '.$YEAR.'} \E!', "\n";
print R '\B!- ! ! ! @'.($teachers_no).' \= \E!', "\n";
print R '\B!: \X{\begin{sideways}Dni tygodnia\end{sideways}} ! \X{\begin{sideways}Godzina lekcyjna\end{sideways}} ! Czas trwania ';
foreach (sort keys %teachers)
{
    print R '! \X{\begin{sideways}', namei($teachers{$_}),'\end{sideways}}  ';
}
print R '\E!', "\n";

print R '\=', "\n";

for my $d (1..5)
{
    for my $h ($hours_start..$hours_end) # (0..9)
    {

        print R '\B!=1cm ';
        print(R '\X{\begin{sideways}\Large ', $ini->{dnitygodnia}->{$d}, '\end{sideways}} ') if $h == 4;

        print R " ! $h. ";
        print R " ! ", fgodz($ini->{godziny}->{$h}), " ! ";


        my $k = 0;
        foreach (sort keys %teachers)
        {
            $k++;

            my $x = $tcr->{$_}->{$d * 10 + $h};

            my $p = "";
            my $s = undef;
            if ($x)
            {
                if (exists $x->{przedmiot}) # no join
                {
                    if ($x->{klasa} eq "9x")
                    {
                        if ($x->{przedmiot} =~ /^t[ms]$/)
                        {
                            $p = "T"; # tuzinki
                        }
                        elsif ($x->{przedmiot} =~ /^l$/)
                        {
                            $p = "L"; # liceum
                        }
                        else
                        {
                            $p = "K"; # kolo
                        }
                    }
                    else
                    {
                        $p = fklasa_footnotesize($x->{klasa});
                    }

                    $s = $x->{sala} // "yyyy";
                    $s = '-' if $s > 1000;
                }
                else # join
                {
                    my $pp = undef;
                    foreach my $j (sort keys %{$x})
                    {
                        $p .= fklasa_footnotesize($x->{$j}->{klasa}).", ";
                        $s = $x->{$j}->{sala} unless defined $s;
                    }
                    $p =~ s/, $//;

                    # foreach my $j (keys %{$x}) # wersja ze scalaniem
                    # {
                    #     my ($k1, $k2) = split//, klasaunfix($x->{$j}->{klasa}), 2;
                    #     $pp->{$k1}->{uc($k2)} = 1;
                    # }

                    # foreach my $k1 (sort keys %{$pp})
                    # {
                    #     $p .= $rom{$k1};
                    #     $p .= '\footnotesize{';
                    #     foreach my $k2 (sort keys %{$pp->{$k1}})
                    #     {
                    #         $p .= $k2;
                    #     }
                    #     $p .= '}, ';

                    # }

                }

                foreach (keys %{$x->{flaga}}) { $p .= $fx{$_} if m/[PBG]/ } #???

                $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};

                $p = '\X{'.$p.'\\\\{}'.$s.'}';

            }

            print R " $p ";
            print R " ! " if ($k < $teachers_no);
        }

        print R '\E!', "\n";
        if ($h < $hours_end)
        {
            print R '\B!- | @'.($teachers_no+2).' \- \E!', "\n" ;
        }
        else
        {
            print R '\=', "\n" ;
        }

    }
}

print R '\=', "\n";

print R $footer;
open(H, "footer.tex.txt"); while (<H>) { print R $_; }; close(H);
close(R);


#################################
# report 3
# rooms/hours
print STDERR "### R3\n" if $DEBUG;
open(R, ">r3.tex");
open(H, "header.tex.txt"); while (<H>) { print R $_; }; close(H);

print R '\=', "\n";
print R '\B!=2cm ! ! ! @'.($rooms_no - 2).' \center{\Huge\sffamily\bfseries S A L E}  " @2 \center{\Large\bfseries '.$YEAR.'} \E!', "\n";
print R '\B!- ! ! ! @'.($rooms_no).' \= \E!', "\n";
print R '\B!: \X{\begin{sideways}Dni tygodnia\end{sideways}} ! \X{\begin{sideways}Godzina lekcyjna\end{sideways}} ! Czas trwania ';
foreach (sort { $a <=> $b } keys %{$room})
{
    next if $_ >= 1000;
    $_ = $ini->{sale}->{$_} if exists $ini->{sale}->{$_};
    print R '! \Large ', $_,' ';
}
print R '\E!', "\n";

print R '\=', "\n";

for my $d (1..5)
{
    for my $h ($hours_start..$hours_end) # (0..9)
    {

        print R '\B!=1cm ';
        print(R '\X{\begin{sideways}\Large ', $ini->{dnitygodnia}->{$d}, '\end{sideways}} ') if $h == 4;

        print R " ! $h. ";
        print R " ! ", fgodz($ini->{godziny}->{$h}), " ! ";


        my $k = 0;
        foreach (sort { $a <=> $b } keys %{$room})
        {

            next if $_ >= 1000;
            $k++;

            my $x = $room->{$_}->{$d * 10 + $h};

            my $p = "";

            if ($x)
            {
                if (exists $x->{nauczyciel}) # no join
                {
                    $p = '\footnotesize '.namei($teachers{$x->{nauczyciel}});
                }
                elsif (scalar(keys(%{$x})) == 1) # only 1 in join
                {
                    my @a = keys(%{$x});
                    $p = '\footnotesize '.namei($teachers{$x->{$a[0]}->{nauczyciel}});
                }
                else
                {
                    my %tt = ();
                    foreach my $j (keys %{$x})
                    {
                        $tt{$x->{$j}->{nauczyciel}} = 1;

                    }

                    $p .= '\X{';
                    foreach my $t (sort keys %tt)
                    {
                        $p .= '\footnotesize '.namei($teachers{$t}).'\\\\{}';
                    }

                    $p =~ s/\\\\\{\}$//;
                    $p .= '}';
                }

            }

            print R " $p ";
            print R " ! " if ($k < $rooms_no);
        }

        print R '\E!', "\n";
        if ($h < $hours_end)
        {
            print R '\B!- | @'.($rooms_no+2).' \- \E!', "\n" ;
        }
        else
        {
            print R '\=', "\n" ;
        }

    }
}

print R '\=', "\n";

print R $footer;
open(H, "footer.tex.txt"); while (<H>) { print R $_; }; close(H);
close(R);

#################################
# report 4
# teachers/small
for my $use_colors (0..2)
{

print STDERR "### R4 use_colors=$use_colors\n" if $DEBUG;
open(R, ">r4_${use_colors}.tex");
open(H, "header_a4.tex.txt"); while (<H>) { print R $_; }; close(H);

my $ci = 0;
while (1)
{
    last unless exists $ini->{colors}->{$ci};
    # my $coloranch = chr($ci+97);
    # print R "\\rectfill {$ini->{colors}->{$ci}} $coloranch\n" if $use_colors;    
    $ci++;
}
my $total_colors = $ci-1;

my $k = 0;
foreach my $t (sort keys %teachers)
{
    $k++;
    
    my $colortab = undef; # hashref klasa -> color-index
    my $next_color = 0;

    print R '\beginanchtable', "\n";
    print R '\begintableformat &\center \endtableformat', "\n";

    print R '\=', "\n";
    print R '\B!=1cm @7 \Large{', $teachers{$t}->{imie_nazwisko}, '}\E!', "\n\n\n";
    print R '\=', "\n";

    print R '\B!: ! od - do ';
    for my $d (1..5) { print R '! ', $ini->{dnitygodnia}->{$d}; }
    print R '\E!', "\n";

    print R '\=', "\n";

    my $anchor = 0;
    for my $h ($hours_start..$hours_end) # (0..9)
    {

        my $eoc = 1;
        for my $d (1..5)
        {
            for my $hh ($h..9)
            {
                my $x = $tcr->{$t}->{$d * 10 + $hh};
                if ($x)
                {
                    $eoc = 0;
                    last;
                }
            }
        }

        last if $eoc;

        my $row = '\B!=1cm ' . " $h. ! " . fgodz($ini->{godziny}->{$h}) . " ! ";
        my $prerow = "";
        my $postrow = "";
        for my $d (1..5)
        {

            my $x = $tcr->{$t}->{$d * 10 + $h};

            my $p = "";

            my $thisklasa = undef;
            if ($x)
            {

                if (exists $x->{przedmiot}) # no join
                {
                    if ($x->{klasa} eq "9x")
                    {
                        if ($x->{przedmiot} eq 'tm') { $p = "T Mł."; } # tuzinki
                        elsif ($x->{przedmiot} eq 'ts') { $p = "T St."; } # tuzinki
                        elsif ($x->{przedmiot} eq 'l') { $p = "L"; } # tuzinki
                        else { $p = "Wszyscy"; } # kolo
                    }
                    else
                    {
                        $p = fklasa_footnotesize($x->{klasa});
                    }

                    $thisklasa = $p;

                    my $s = $x->{sala};
                    $s = "-" if $s > 1000;
                    $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};
                    $p = '\X{' . $ini->{przedmioty}->{$x->{przedmiot}} . '\\\\' . "$p [$s] }";
                }
                else
                {
                    my $s = "XXX";
                    my $pp = "YYY";

                    foreach my $j (keys %{$x})
                    {
                        next unless exists $x->{$j}->{klasa};
                        $p .= fklasa_footnotesize($x->{$j}->{klasa}) . " ";
                        

                        if (exists $x->{$j}->{sala})
                        {
                            $s = $x->{$j}->{sala};
                            $s = "-" if $s > 1000;

                            $s = $ini->{sale}->{$s} if exists $ini->{sale}->{$s};
                        }

                        if (exists $x->{$j}->{przedmiot})
                        {
                            $pp = $ini->{przedmioty}->{$x->{$j}->{przedmiot}};
                        }

                    }

                    $thisklasa = $p;

                    $p = '\X{' . $pp . '\\\\' . "$p [$s]" . '}';

                }

# not important here                foreach (keys %{$x->{flaga}}) { $p .= $fx{$_} if m/[PBG]/ } #???

            }

            if ($use_colors)
            {
                my $thiscolor = 0;
                if (defined $thisklasa)
                {
                    if (exists $colortab->{$thisklasa})
                    {
                        $thiscolor = $colortab->{$thisklasa};
                    }
                    else
                    {
                        die "not enough colors: ".Dumper($colortab) if $next_color > $total_colors;
                        $thiscolor = $next_color;
                        $colortab->{$thisklasa} = $thiscolor;
                        $next_color++;
                    }

                    my $col = $d+2;
                    # my $coloranch = chr($thiscolor+97);
                    $prerow .= "\\brectangle nl $col \{anchor$anchor\} ";
                    $postrow .= "\\erectangle \{$ini->{colors}->{$thiscolor}\} nr $col \{anchor$anchor\} ";
                    $anchor++; # if $anchor < 9;
                }
            }

            $p .= '!' if $d < 5;
            
            $row .= $p;
        }

        print R $use_colors ? "$prerow \n$row\\E! \n$postrow \n" : "$row\\E!\n";
        print R '\-', "\n" ;

        # przerwy
        print R '\B!: ! ', fgodz($ini->{przerwy}->{$h}), ' ! ! ! ! ! \E!',"\n";
        print R '\-', "\n";

    }
    print R '\endanchtable ', "\n\n\n";
    print(R '\clearpage', "\n") if $use_colors == 2; # ($k%2 == 0);
}


open(H, "footer.tex.txt"); while (<H>) { print R $_; }; close(H);
close(R);

} # r4 colors