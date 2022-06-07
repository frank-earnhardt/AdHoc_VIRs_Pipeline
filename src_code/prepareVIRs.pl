use Getopt::Std;
use Cwd;
use Encode;
#use Text::CSV;
#use IO::All;
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
my %MASTER;
my @DATA_FILES = &selectSrcData($PATH,$EXT);
if (scalar(@DATA_FILES) > 0) {
    for (my $dfi=0;$dfi<scalar(@DATA_FILES);$dfi++) {
        my $dfile = $DATA_FILES[$dfi];
        printf "  %0.2d == %-s\n",$dfi,$DATA_FILES[$dfi];
        my @DATA = &loadFile($dfile,"\\|","Y","vehicle_id","#");
        if (scalar(@DATA) > 0) {
            for (my $dxi=1;$dxi<scalar(@DATA);$dxi++) {
                my %ROW = &hashDATA($DATA[0],$DATA[$dxi]);
                $ROW{"FILE"}=&File($dfile);
                #my $vid = $ROW{"vehicle_id"} . "!" . $ROW{"inspection_date"};
                my $vid = $ROW{"vehicle_id"};
                if (!exists($MASTER{$vid})) {$MASTER{$vid}="";}
                if ($MASTER{$vid} eq "") {
                    $MASTER{$vid} = \%ROW;
                } else {
                    my $cFlag=0;
                    print "  ERROR: Vehicle_Id[$vid] Already Exists!\n";
                    my %PREDATA = %{$MASTER{$vid}};
                    printf "  %-45s %-45s %-45s %-10s\n","COLUMN","PRE_DATA","CUR_DATA","COMPARE";
                    foreach my $pkey(sort keys %PREDATA) {
                        my $pval = $PREDATA{$pkey};
                        my $cval = $ROW{$pkey};
                        my $cmp="UNK";
                        if ($pval eq $cval) {
                            $cmp="SAME";
                        } else {
                            $cmp="DIFF";
                            if ($pkey ne "FILE" || $pkey ne "LOG" ) {
                                $cFlag++;
                                if (!exists($ROW{"LOG"})) {$ROW{"LOG"}="";}
                                if ($ROW{"LOG"} eq "") {
                                    $ROW{"LOG"} = "${pkey}|${pval}|${cval}|" . $ROW{"FILE"};
                                } else {
                                    $ROW{"LOG"} .= "!-!${pkey}|${pval}|${cval}|" . $ROW{"FILE"};
                                }
                            }
                        }
                        printf "  %-45s %-45s %-45s %-10s\n",$pkey,$pval,$cval,$cmp;
                    }
                    $MASTER{$vid} = \%ROW;
                    if (uc($MODE) !~ /CRON/) {
                        <STDIN> if $cFlag > 0;
                    }
                }
                print "VID:$vid\n";
                my $idt = $ROW{"inspection_date"};
                my $vog = $ROW{"vehicle_org_id"};

                foreach my $rowkey(sort keys %ROW) {
                    my $rowval = $ROW{$rowkey};
                    printf "  ROW:%0.2d COL:%-45s == %-s\n",$dxi,$rowkey,$rowval;
                }
            }
            <STDIN> if $DEBUG > 0;
        }
    }
} else {
    print "  No Data Files to process!\n";
}
#################################
## BEGIN BUSINESS LOGIC
#################################
# 1. MVP Report TSV org_name\ttot_v\tfailed_v
my %MVP_RPT;
my %ORG_REF;
if (scalar(keys %MASTER) > 0) {
    foreach my $key(sort keys %MASTER) {
        printf "  Vehicle_ID:%-s\n",$key;
        my %vals = %{$MASTER{$key}};
        ###############################
        # 1. Begin MVP
        my $mvp_key = $vals{"vehicle_org_id"};
        if (!exists($ORG_REF{$mvp_key})) {$ORG_REF{$mvp_key}="";}
        if ($ORG_REF{$mvp_key} eq "") {
            $ORG_REF{$mvp_key}=$vals{"org_name"};
        } else {
            print "  WARNING: DUPLICATE ORG_NAMES\n";
        }
        print "  MVP_KEY:$mvp_key\n";
        my $mvp_val = $vals{"inspection_passed"};
        print "  MVP_VAL:$mvp_val\n";
        if (!exists($MVP_RPT{$mvp_key}->{"VLIST"})) {$MVP_RPT{$mvp_key}->{"VLIST"}="";}
        if ($MVP_RPT{$mvp_key}->{"VLIST"} eq "") {
            $MVP_RPT{$mvp_key}->{"VLIST"}=$key;
        } else {
            $MVP_RPT{$mvp_key}->{"VLIST"}.="," . $key;
        }
        if (!exists($MVP_RPT{$mvp_key}->{"total_v"})) {$MVP_RPT{$mvp_key}->{"total_v"}=0;}
        if ($MVP_RPT{$mvp_key}->{"total_v"} == 0) {
            $MVP_RPT{$mvp_key}->{"total_v"}=1;
        } else {
            $MVP_RPT{$mvp_key}->{"total_v"}=$MVP_RPT{$mvp_key}->{"total_v"} + 1;
        }
        
        if (!exists($MVP_RPT{$mvp_key}->{"FLIST"})) {$MVP_RPT{$mvp_key}->{"FLIST"}="";}
        if ($mvp_val ne "TRUE") {
            if ($MVP_RPT{$mvp_key}->{"FLIST"} eq "") {
                print "  SET:FLIST=$key\n";
                $MVP_RPT{$mvp_key}->{"FLIST"}=$key;
            } else {
                print "  APPEND:FLIST:$key\n";
                $MVP_RPT{$mvp_key}->{"FLIST"}.="," . $key;
            }
        }
        if (!exists($MVP_RPT{$mvp_key}->{"failed_v"})) {$MVP_RPT{$mvp_key}->{"failed_v"}=0;}
        if ($mvp_val ne "TRUE") {
            if ($MVP_RPT{$mvp_key}->{"failed_v"} == 0) {
                print "  SET:FAILED=1\n";
                $MVP_RPT{$mvp_key}->{"failed_v"}=1;
            } else {
                print "  APPEND:FAILED=+1\n";
                $MVP_RPT{$mvp_key}->{"failed_v"}=$MVP_RPT{$mvp_key}->{"failed_v"} + 1;
            }
        }
        # 1. End MVP
        #######################################
        foreach my $vkey(sort keys %vals) {
            my $val = $vals{$vkey};
            next if ($vkey eq "LOG");
            printf "  --%-41s == %-s\n",$vkey,$val;
        }
        if (exists($vals{"LOG"})) {
            my @LOGS = split('!-!',$vals{"LOG"});
            if (scalar(@LOGS) > 0) {
                for (my $li=0;$li<scalar(@LOGS);$li++) {
                    my ($attr,$was,$now,$file) = split('\|',$LOGS[$li]);
                    printf "  %0.2d == COL:${attr} changed FROM:${was} TO:${now} BY:${file}\n",$li;
                }
            }
        }
    }
} else {
    print "  MASTER HASH IS EMPTY!\n";
}
#############
# MVP REPORT
if (scalar(keys %MVP_RPT) > 0) {
    my $mvpRpt = "${PATH}${SLASH}virs_report\.tsv";
    open(FH,"> $mvpRpt") || die "Unable to open $mvpRpt";
    print "******************************************\n";
    print "** MVP REPORT - org_name  total  failed **\n";
    print "******************************************\n";
    print FH "org_name\ttot_v\tfailed_v\n";
    printf "  %10s %-20s %7s %8s\n","org_id","org_name","total_v","failed_v";
    printf "  %10s %-20s %7s %8s\n","----------","--------------------","-------","--------";
    foreach my $mvp_key(sort keys %MVP_RPT) {
        my $mvp_tot_v = $MVP_RPT{$mvp_key}->{"total_v"};
        my $mvp_failed_v = $MVP_RPT{$mvp_key}->{"failed_v"};
        printf "  %10s %-20s %7s %8s\n",$mvp_key,$ORG_REF{$mvp_key},$mvp_tot_v,$mvp_failed_v;
        print "  -V-" . $MVP_RPT{$mvp_key}->{"VLIST"} . "\n";
        if (exists($MVP_RPT{$mvp_key}->{"FLIST"})) {
            print "  -F-" . $MVP_RPT{$mvp_key}->{"FLIST"} . "\n";
        }
        print FH "$ORG_REF{$mvp_key}\t${mvp_tot_v}\t${mvp_failed_v}\n";
    }
    close(FH);
    if (-f $mvpRpt) {
        print "  --See: $mvpRpt\n";
    }
}
sub selectSrcData {
    my $path = shift || "";
    my $fext = shift || "";
    if (! -d $path) {
        print "  selectData($path,$ext) ERROR: Invalid Path: $path\n";
        return;
    }
    my $cmd="find ${path} -exec file {} \\;";
    if ($EXT ne "") {$cmd .= " | grep ${EXT}";}
    $cmd .= " | sort -n";
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
        my @RTN;
        for (my $rx=0;$rx<scalar(@R);$rx++) {
            my $rline = $R[$rx];
            printf "  %0.12d %-s\n",$rx,$rline if $DEBUG > 0;
            my $file = $rline;
            $file =~ s/\:.*//g;
            push(@RTN,$file);
        }
        return @RTN;
    } else {
        print "  Nothing returned from cmd: $cmd\n";
    }
}
sub hashDATA {
    $|=1;
    my $head = shift || "";
    my $data = shift || "";
    my @T = split('|',$data);
    for (my $ti=0;$ti<scalar(@T);$ti++) {
        my $tval = ord($T[$ti]);
        printf "  %0.2d == %-s\n",$ti,$tval;
    }
    my @H = split('\|',$head);
    print "[", join(":", @H), "]\n";
    my $hcnt = scalar(@H);
    my @D = split('\|',$data);
    print "[" . join(":", @D), "]\n";
    my $dcnt = scalar(@D);
    print "HEAD[${hcnt}]:$head\n";
    print "DATA[${dcnt}]:$data\n";
    my %HASH_DATA = map { $H[$_] => $D[$_] } (0..@H - 1 => 0..@D - 1);
    foreach my $key(sort keys %HASH_DATA) {
        my $val = $HASH_DATA{$key};
        printf "  %-45s == %-s\n",$key,$val;
    }
    $|=0;
    return %HASH_DATA;
}
sub splitData {
    my $in_data = shift || "";
    my @OUT = split('\|',$in_data);
    print "  $in_data\n";
    print "  data_col:" . scalar(@OUT) . "\n";
    if (scalar(@OUT) > 0) {
        for (my $oi=0;$oi<scalar(@OUT);$oi++) {
            my $val = $OUT[$oi];
            printf "  %0.2d == %-s\n",$oi,$val;
        }
        <STDIN>;
        return @OUT;
    }
}
sub loadFile {
    my $file = shift || "";
    print "$file\n" if $DEBUG > 0;
    if (-f $file) {
        open(FH,"< $file")||die "Unable to open file: $file";
        $/ = "\cA";
        my $data_slurp = do { local $/; <FH> };
        close(FH);
        print "*******${data_slurp}************\n";
        $/ = "\n";
        if ($data_slurp =~ /<?xml[^>]+encoding[\s\x0d\x0a]*=[\s\x0d\x0a]*['"]utf-?8/i || $file =~ /<meta[^>]+chatset[\s\x0d\x0a]*=[\s\x0d\x0a]*utf-?8/i) {
            $data_slurp = decode('utf-8', $data_slurp);
        }
        $data_slurp =~ s/(.)/asciiize($1)/eg;
        print "*******${data_slurp}************\n";
        my @RTN = split('\r\n',$data_slurp);
        return @RTN;
    } else {
        print "  Could not locate file: $file\n";
    }
}
sub asciiize {
    return $_[0] if (ord($_[0]) < 128);     # ASCII
    return sprintf('&#x%04X;', ord($_[0])); # Non-Ascii
}
sub loadFile2 {
    print "  loadFile()\n";
    my $file= shift || "";
    my $col_sep = shift || "\\|";
    my $has_head = shift || "";
    my $col_key = shift || "";
    my $has_cmt = shift || "";

    print "$file\n" if $DEBUG > 0;
    if (-f $file) {
        undef $/;
        open(FH,"< $file")||die "Unable to open file: $file";
        my $rowCnt=0;
        my $head="";
        my @H;
        my %HEADER;
        my %DATA;
        while(<FH>) {
            my $line = $_;
            chomp($line);
            chop($line);
            print "  Line1:'${line}'\n" if $DEBUG > 0;
            if ($has_cmt ne "") {
                if ($line =~ /${has_cmt}/) {
                    print "  has_cmt:${has_cmt}\n";
                    next;
                }
            }
            #my @ROW_DATA=split(${col_sep},$line);
            my @ROW_DATA=split(/\|/,$line);
            if ($has_head ne "" && $rowCnt == 0) {
                print "  Has HEADER:'${line}'\n";
                @H=@ROW_DATA;
                if (scalar(@H) > 0) {
                    for (my $hi=0;$hi<scalar(@H);$hi++) {
                        my $hcol = $H[$hi];
                        printf "  HROW: %0.4d:%0.2d == %-s\n",$rowCnt,$hi,$hcol if $DEBUG > 0;
                        $HEADER{$hcol}=$hi;
                        $head=$line;
                    }
                } else {
                    die "  ERR: Header is emply!\n";
                }
                $rowCnt++;
                <STDIN> if $DEBUG > 9;
                next;
            }
            $rowCnt++;
            print "  Line2:$line\n" if $DEBUG > 0;
            my %ROW;
            print "----------------------------------------------------------------------------\n";
            for (my $rdi=0;$rdi<scalar(@ROW_DATA);$rdi++) {
                my $col = &cleanStr($H[$rdi]);
                my $val = $ROW_DATA[$rdi];
                if ($val == undef) {
                    printf "  -ERR: %0.4d:%0.2d == COL:%-30s\n",$rowCnt,$rdi,$col;
                    $val="nil";
                }
                printf "  DROW: %0.4d:%0.2d == COL:%-30s VAL:%-s\n",$rowCnt,$rdi,$col,$val if $DEBUG > 0;
                $ROW{"${col}"}="${val}";
            }
            print "----------------------------------------------------------------------------\n";
            for (my $hi=0;$hi<scalar(@H);$hi++) {
                my $hcol = $H[$hi];
                my $hval = $ROW{${hcol}};
                if (!exists($ROW{$hcol})) {
                    $hval ="ERR: Something wrong with hcol:'${hcol}'";
                    printf "  -BAD: %0.4d:%0.2d COL:%-30s\n",$rowCnt,$hi,$hcol;
                    foreach my $rowkey(sort keys %ROW) {
                        my $rowval = $ROW{$rowkey};
                        my $chk = "UKN";
                        if ($rowkey eq $hcol) {
                            $chk="MATCH";
                        }
                        printf "  -BUG: %0.4d:%0.2d COL:%-30s == %-50s %-s\n",$rowCnt,$hi,"'${rowkey}'","'${rowval}'",$chk;
                    }
                    printf "  FILE: %0.4d:%0.2d %-s\n",$rowCnt,$hi,$file;
                    printf "  HEAD: %0.4d:%0.2d %-s\n",$rowCnt,$hi,$head;
                    printf "  LINE: %0.4d:%0.2d %-s\n",$rowCnt,$hi,$line;
                    &pullROWS($file,$rowCnt,$rowCnt);
                    <STDIN>;
                }
                printf "  FROW: %0.4d:%0.2d COL:%-30s == %-s\n",$rowCnt,$hi,$hcol,$hval;
            }
            <STDIN> if $DEBUG > 9;
        }
        close(FH);
    } else {
        print "  loadFile() ERROR: Could not locate file: $file\n";

    }
}
sub pullROWS {
    my $file = shift || "";
    my $srow = shift || "";
    my $erow = shift || $srow;
    if (-f $file) {
        my $cmd="/usr/bin/sed -n ${srow},${erow}p ${file}";
        print "  $cmd\n";# if $DEBUG > 0;
        my $cmdX=`$cmd`;
        chomp($cmdX);
        my @R=split('\n',$cmdX);
        if (scalar(@R) > 0) {
            for (my $rx=0;$rx<scalar(@R);$rx++) {
                printf "  %0.12d %-s\n",$rx,$R[$rx];# if $DEBUG > 0;
            }
        } else {
            print "  Nothing returned from cmd: $cmd\n";
        }
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
    my $outStr = $inStr;
    $outStr =~ s/\s+|\s+$//g;
    if ($inStr ne $outStr) {
        print "  -cleanStr($inStr) == $outStr\n";
        <STDIN>;
    }
    return $outStr;
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