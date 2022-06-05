use Getopt::Std;
use Cwd;
#use Mac::AppleSingleDouble;
my $wDir=cwd;
my $SLASH = &getSLASH();
my $dt = sprintf "%0.4d_%0.2d_%0.2d",(localtime())[5]+1900,(localtime())[4] +1,(localtime())[3];
my $tm = sprintf "%0.2d%0.2d%0.2d",(localtime())[2,1,0];
my $now = sprintf "%0.2d/%0.2d/%0.4d %0.2d:%0.2d:%0.2d",(localtime())[4] +1,(localtime())[3],(localtime())[5]+1900,(localtime())[2,1,0];
sub Usage {
    print "   USAGE\n";
    print "        $0 -m<Mode> -d<debugInt> -h\n";
    print "           -m<Mode>        ~ Mode Typical Nothing\n";
    print "                             -- CRON ~ Skip Human Prompts\n";
    print "                             -- SHOW ~ Skip Actual Execution\n";
    print "           -d<debugInt>    ~ debugInt Indicator\n";
    print "           -h              ~ Shows Usage\n";
}
my $base=$0;
print "${wDir}${SLASH}${base}\n";
getopts('m:p:e:d:h');
my $MODE           = $opt_m || "";
my $PATH           = $opt_p || &Parent(${wDir}) . "${SLASH}src_data";
my $EXT            = $opt_e || "text";
my $DEBUG          = $opt_d || 0;
if ($opt_h) {&Usage; exit 0;}
my @DATA = &selectData($PATH,$EXT);

sub selectData {
    my $path = shift || "";
    my $fext = shift || "";
    if (! -d $path) {
        print "  selectData($path,$ext) ERROR: Invalid Path: $path\n";
        return;
    }
    my $cmd="find ${path} -exec file {} \\;";
    if ($EXT ne "") {$cmd .= " | grep ${EXT}";}
    
    print "$cmd\n" if $DEBUG > 0;
    my $cmdX=`$cmd`;
    chomp($cmdX);
    my @RALL=split('\n',$cmdX);
    my @R;
    if (uc($MODE) =~ /CRON/) {
        @R=@RALL;
    } else {
        @R=&fromARRAY(@RALL);
    }
    if (scalar(@R) > 0) {
        for (my $rx=0;$rx<scalar(@R);$rx++) {
            my $rline = $R[$rx];
            printf "  %0.12d %-s\n",$rx,$rline if $DEBUG > 0;
            my $file = $rline;
            $file =~ s/\:.*//g;
            &loadFile($file,"\\|","Y","vehicle_id","#");
        }
    } else {
        print "  Nothing returned from cmd: $cmd\n";
    }
}
sub loadFile {
    print "  loadFile()\n";
    my $file= shift || "";
    my $col_sep = shift || "\\|";
    my $has_head = shift || "";
    my $col_key = shift || "";
    my $has_cmt = shift || "";

    print "$file\n" if $DEBUG > 0;
    if (-f $file) {
        open(FH,"< $file")||die "Unable to open file: $file";
        my $rowCnt=0;
        my $head="";
        my @H;
        my %DATA;
        while(<FH>) {
            my $line = $_;
            chomp($line);
            print "  Line1:$line\n" if $DEBUG > 0;
            if ($has_cmt ne "") {
                if ($line =~ /${has_cmt}/) {
                    print "  has_cmt:${has_cmt}\n";
                    next;
                }
            }
            my @ROW_DATA=split(${col_sep},$line);
            if ($has_head ne "" && $rowCnt == 0) {
                print "  Has HEADER\n";
                @H=@ROW_DATA;
                $rowCnt++;
                next;
            }
            $rowCnt++;
            print "  Line2:$line\n";# if $DEBUG > 0;
            my %ROW;
            print "----------------------------------------------------------------------------\n";
            for (my $rdi=0;$rdi<scalar(@ROW_DATA);$rdi++) {
                my $col = $H[$rdi];
                my $val = $ROW_DATA[$rdi];
                printf "  ROW: %0.4d:%0.2d == COL:%-30s VAL:%-s\n",$rowCnt,$rdi,$col,$val;
                $ROW{$col}=$val;
            }
            print "----------------------------------------------------------------------------\n";
            foreach my $rkey(sort keys %ROW) {
                my $rval = $ROW{$rkey};
                printf "  %-30s == %-s\n",$rkey,$rval;
            }
        }
        close(FH);
    } else {
        print "  loadFile() ERROR: Could not locate file: $file\n";

    }
}
sub fromARRAY {
    print "  =============== FROM ARRAY ===============\n" if $DEBUG > 0;
    my @ARRAY = @_;
    my @RETURN;
    my $ans="";
    if ($MODE ne "NO-PROMPT") {
         for (my $i=0;$i<=scalar(@ARRAY)-1 ;$i++) {
             my $c = $i+1;
             print "\t$c $ARRAY[$i]\n";
     }
         print "\n\tEnter Choice (x~exit| s~skip | n~new) 1,2,ect | 1-5,8-19 | a for all] [a]:";
         $ans = <STDIN>;
         chomp($ans);
         print "\n";
         if (lc($ans) eq "x") {
             &_EXIT_CLEAN("Exit by user!");
         }
         if (lc($ans) eq "s") {return;}
     }
     if ($ans eq "") {
         $ans = "a";
     }
     if ($ans eq "a") {
         print "\t\tLoading All .ftp files\n" if $DEBUG > 0;
         for my $f(@ARRAY) {
             push(@RETURN,$f);
         }
     } else {
         my @INPUT = split(',',$ans);
         my $test="";
         for my $line(@INPUT) {
             print "        *** Looking for Input ($line-1) :" if $DEBUG > 0;
             my ($s,$e) = split('-',$line);
             if (! defined $e) {$e="";}
             if ($e eq "") {
                 $test = $s;
                 $test =~ s/[aA-zZ]//g;
                 if ($test ne "") {
                     if ($ARRAY[$s-1] ne "") {
                         print "Found SPECIFIC: " . $ARRAY[$s-1] . "  ***\n" if $DEBUG > 0;
                         push(@RETURN,$ARRAY[$s-1]);
                     }
                 }
             } else {
                 for (my $int=$s;$int<=$e ;$int++) {
                     $test = $int;
                     $test =~ s/[aA-zZ]//g;
                     if ($test ne "") {
                         if ($ARRAY[$int-1] ne "") {
                             print "Found RANGE" . $ARRAY[$int-1] . "  ***\n" if $DEBUG > 0;
                             push(@RETURN,$ARRAY[$int-1]);
                         }
                     }
                 }
             }
         }
     }
     print "        FROM_ARRAY_RETURN_LIST:\n" if $DEBUG > 0;
     if (scalar(@RETURN) > 0) {
         for (my $ix=0;$ix<=scalar(@RETURN)-1 ;$ix++) {
             print "        --$ix $RETURN[$ix]\n" if $DEBUG > 0;
         }
     } else {
         if ($ans ne "") {push(@RETURN,$ans);}
     }
     return @RETURN;
}
sub cleanStr {
    my $inStr = shift || "";
    if ($inStr eq "") {return $inStr;}
    $inStr =~ s/^\s+//g;
    $inStr =~ s/\s+$//g;
    return $inStr;
}
sub Parent {
    ###########################################################################
    #REMC#  Parent -- return directory portion of pathname (either ".../..." or "...\...")
    #REMC#  arg0 = string to be processed
       my $parent="";
       if ($_[0] =~ m@(.*)[/\\][^\\]+$@) {
          $parent=$1;
       } else {
           $parent=cwd;
       }
    return $parent;
}
sub File {
    my $inStr = shift || "";
    if ($inStr eq "") {return;}
    $inStr =~ s!^.*\\!!;
    $inStr =~ s!^.*/!!;
    return $inStr;
}
sub getSLASH {
###########################################################################
#REMS#  getSLASH() --  Get either \ or / depending on OS
#REMS#  Return: SLASH
   my $SLASH="";
   if ($^O =~ /Win/) {
       $SLASH = "\\";
   }else {
       $SLASH = "/";
   }
   return $SLASH;
}