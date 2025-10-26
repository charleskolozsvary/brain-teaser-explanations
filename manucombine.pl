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
            outname => 'combined.tex',
            class   => '');

#########################################################
##                                                     ##
##                         USAGE                       ##
##                                                     ##
#########################################################

sub usage() {
    my $usage = << "EOF";
Usage: $program_name [options] filenames-file

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

where `filenames-file' contains
```
texfile1.tex
texfile2.tex
texfile3.tex
etc.
```

Each tex file in filenames-file is assumed to be of the form
```tex
\\documentclass{[class]}
\\input{preamble.tex}
\\begin{document}
[body]
\\end{document}
```


Options:
    -help               : Print this help text and quit.

    -preamble=filename  : Specify a common preamble file (default is 'preamble.tex')

    -outname=filename   : Specify combined file name (default is 'combined.tex')

    -class=string       : Specify the argument of \\documentclass{}
                          (default is 'book')

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

sub getFilenames {
    my $filename_file = shift;
    my $text = getFileText($filename_file);
    my @filenames = $text =~ m{(\S+)}g;
    return @filenames;
}

sub combineFiles {
    my $filename_file = shift;
    
    my $outname = $OPT{outname};
    my $preamblefname = $OPT{preamble};
    my $class = !$OPT{class} ? 'book' : $OPT{class};

    my @filenames = getFilenames($filename_file);

    my $bodies = getBodies(@filenames);

    open(my $combFH, '>', $outname) or die "Couldn't write to $outname $!";

    print $combFH "\\documentclass{$class}\n\\input{$preamblefname}\n\\begin{document}\n";

    print $combFH $bodies;

    print $combFH "\\end{document}\n";

    close $combFH;
    
}

#########################################################
##                                                     ##
##                          MAIN                       ##
##                                                     ##
#########################################################

GetOptions("class=s"     => \$OPT{class},
	   "outname=s"   => \$OPT{outname},
	   "preamble=s"  => \$OPT{preamble},
	   "help"        => \&usage,
    ) or usage;

usage unless @ARGV == 1;

if (! -e $OPT{preamble}){
    die "File '$OPT{preamble}' does not exist. Aborting $program_name\n";
}

if ($OPT{class} && (! $OPT{class} =~ m{^(?:article|book)$})){
    die "Document class '$OPT{class}' neither book or article. Aborting $program_name.\n";
}

my $filenames_file = shift;

combineFiles($filenames_file);
