#!/usr/bin/perl -w
use v5.26;
use warnings;
use Getopt::Long qw(:config no_ignore_case);

#########################################################
##                                                     ##
##                       CONSTANTS                     ##
##                                                     ##
#########################################################

our $program_name = 'manucombine.pl';

our %OPT = (addto    => '',
            preamble => 'preamble.tex',
            combinedf => 'combined.tex',
            class   => '');

#########################################################
##                                                     ##
##                         USAGE                       ##
##                                                     ##
#########################################################

sub usage() {
    my $usage = << "EOF";
Usage: $program_name [options] tex_file1 tex_file2 tex_file3 etc.

Combine LaTeX files into one, including from each only what is between
\\begin{document} and \\end{document}.

The form of the combined file is
```tex
\\documentclass{[class]}
\\input{preamble}
\\begin{document}
[body of tex_file1]
[body of tex_file2]
[etc.]
\\end{document}
```

Options:
    -help               : Print this help text and quit.

    -addto=filename     : Add files to the body of the supplied file

    -preamble=filename  : Specify a common preamble file (default is 'preamble.tex')

    -combinedf=filename : Specify combined file name (default is 'combined.tex')

    -class=string       : Specify the argument of \\documentclass{}
                          (default is 'article')

EOF

    print($usage);

    exit 1;
}

#########################################################
##                                                     ##
##                      SUBROUTINES                    ##
##                                                     ##
#########################################################

sub getFileText {
    my $fname = shift;
    open(my $fh, '<', $fname) or die "Could not read file '$fname' $!";
    $/ = undef; #slurp mode
    my $file_text = <$fh>;
    close $fh;
    $/ = "\n";
    return $file_text;
}

sub getUpToEnd {
    my $fname = shift;
    my $file_text = getFileText($fname);
    $file_text =~ m{(?<up_to_end>.*?)\\end\s*\{\*document\*\}}s; #s modifier so . matches \n
    return $+{up_to_end};
}

sub getBodies {
    my @filenames = @_;
    my $bodies = '';
    $/ = undef; #slurp mode
    foreach my $fname (@filenames){
	my $file_text = getFileText($fname);
	$file_text =~ m{\\begin\s*\{document\}\s*(?<body>.*?)\\end\s*\{document\}}s; #s modifier so . matches \n
	$bodies .= "% START OF FILE '$fname'\n" . $+{body} . "% END OF FILE '$fname'\n";
    }
    return $bodies;
}

sub combineFiles {
    my @filenames = @_;
    
    my $combinedfname = $OPT{combinedf};
    my $preamblefname = $OPT{preamble};
    my $class = !$OPT{class} ? 'article' : $OPT{class};

    my $bodies = getBodies(@filenames);

    open(my $combFH, '>', $combinedfname) or die "Couldn't write to $combinedfname $!";

    if ($OPT{addto}){
	print $combFH getUpToEnd($combinedfname);
    }
    else {
	print $combFH "\\documentclass{$class}\n\\input{$preamblefname}\n\\begin{document}\n";
    }

    print $combFH $bodies;

    print $combFH "\\end{document}\n";

    close $combFH;
    
}

#########################################################
##                                                     ##
##                          MAIN                       ##
##                                                     ##
#########################################################

GetOptions("addto=s"     => \$OPT{addto},
	   "preamble=s"  => \$OPT{preamble},
	   "combinedf=s" => \$OPT{combinedf},
	   "class=s"     => \$OPT{class},
	   "help"        => \&usage,
    ) or usage;

usage unless @ARGV > 0;

if ($OPT{addto}){
    $OPT{combinedf} = $OPT{addto};
    if (! -e $OPT{combinedf}){
	die "File to add to '$OPT{combinedf}' does not exist. Aborting $program_name";
    }
    if ($OPT{class}){
	print "WARNING: You have supplied -class with -addto which will be ignored.\n(The document class of the file to add to is not overwritten.)\n";
    }
    if ($OPT{preamble}){
	print "WARNING: You have supplied -preamble with -addto which will be ignored.\n(The preamble of the file to add to is not overwritten.)\n";
    }
}

if (-e $OPT{combinedf}){
    print "file $OPT{combinedf} already exists, overwrite it? (yes/no)\n";
    my $answer = <STDIN>;
    die "Aborting $program_name" if !($answer =~ m{^yes\n$}i);
}

combineFiles(@ARGV);
