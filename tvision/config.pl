#!/usr/bin/perl
#
# To specify the compilation flags define the CFLAGS environment variable.
#

require "miscperl.pl";

GetCache();
GetVersion('');

$ErrorLog='errormsg.txt';
# I never tested with an older version, you can try reducing it.
$GPMVersionNeeded='1.13';
# I never tested with an older version, you can try reducing it.
$NCursesVersionNeeded='1.9.9';
# Adds some nice stuff to define key sequences.
$NCursesVersionRecomended='4.2';
$DJGPPVersionNeeded='2.0.2';

SeeCommandLine();

print "Configuring Turbo Vision v$Version library\n\n";
# Determine the OS
$OS=DetectOS();
# Determine C flags
$CFLAGS=FindCFLAGS();
# Test for a working gcc
$GCC=CheckGCC();
# Check if gcc can compile C++
$GXX=CheckGXX();
# Is the right djgpp?
if ($OS eq 'dos')
  {
   LookForDJGPP($DJGPPVersionNeeded);
  }

if ($OS eq 'linux')
  {
   LookForGPM($GPMVersionNeeded);
   LookForNCurses($NCursesVersionNeeded,$NCursesVersionRecomended);
   LookForKeysyms();
  }
LookForIntlSupport();
LookForPrefix();

print "\n";
GenerateMakefile();
ModifyMakefiles('linux/Makefile','djgpp/makefile');
CreateRHIDEenvs('linux/rhide.env','djgpp/rhide.env','examples/config.env');
CreateConfigH();

print "\nSuccesful configuration!\n\n";

GiveAdvice();
CreateCache();
unlink $ErrorLog;

sub SeeCommandLine
{
 my $i;

 foreach $i (@ARGV)
   {
    if ($i eq '--help')
      {
       ShowHelp();
       die "\n";
      }
    else {
    if ($i=~'--prefix=(.*)')
      {
       @conf{'prefix'}=$1;
      }
    else {
    if ($i eq '--no-intl')
      {
       @conf{'no-intl'}='yes';
      }
    else
#    if ($i=~'--cflags=(.*)')
#      {
#       @conf{'CFLAGS'}=$1;
#      }
#    else
      {
       ShowHelp();
       die "Unknown option: $i\n";
      }}}
   }
}

sub ShowHelp
{
 print "Available options:\n\n";
 print "--help         : displays this text.\n";
 print "--prefix=path  : defines the base directory for installation.\n";
 print "--no-intl      : don't use international support.\n";
}

sub GiveAdvice
{
 if ((@conf{'intl'} eq 'no') && (@conf{'no-intl'} ne 'yes'))
   {
    print "\n";
    print "* The international support was disabled because gettext library could not\n";
    print "  be detected.\n";
    if ($OS eq 'linux')
      {
       print "  Starting with glibc 2.0 this is included in libc, perhaps your system\n";
       print "  just lacks the propper header file.\n";
      }
    else
      {
       print "  Install the gtxtNNNb.zip package from the v2gnu directory of djgpp's\n";
       print "  distribution. Read the readme file for more information.\n";
      }
   }
}

sub DetectOS
{
 my $os,$OS;
 $os=`uname`;
 print 'Determining OS: ';
 
 if ($os=~/MS\-DOS/)
   {
    $OS='dos';
    $stdcxx='-lstdcxx';
    $defaultCXX='gxx';
   }
 else
   {
    if ($os=~/[Ll]inux/)
      {
       $OS='linux';
       $stdcxx='-lstdc++';
       $defaultCXX='g++';
      }
    else
      {
       die('Unknown OS, you must do things by yourself');
      }
   }
 print "$OS\n";
 $OS;
}

sub FindCFLAGS
{
 my $ret;

 print 'Determining the C compilation flags: ';
 $ret=@conf{'CFLAGS'};
 if ($ret)
   {
    print "$ret (cached)\n";
    return $ret;
   }
 $ret=@ENV{'CFLAGS'};
 if (!$ret)
   {
    $ret='-O2 -gstabs+3';
    $ret.=' -pipe' unless ($OS eq 'dos');
   }
 print "$ret\n";
 $conf{'CFLAGS'}=$ret;
 $ret;
}

sub LookForDJGPP
{
 my $vNeed=$_[0];
 my $test;

 print 'Checking DJGPP version: ';
 $test=@conf{'djgpp'};
 if ($test)
   {
    print "$test (cached) OK\n";
    return;
   }
 $test='
#include <stdio.h>
int main(void)
{
 printf("%d.0.%d",DJGPP,DJGPP_MINOR);
 return 0;
}';
 $test=RunGCCTest($GCC,'c',$test,'');
 if (!CompareVersion($test,$vNeed))
   {
    print "\nWrong DJGPP version, please use $vNeed or newer\n";
    print "Look in $ErrorLog for potential compile errors of the test\n";
    CreateCache();
    die "Wrong version\n";
   }
 print "$test OK\n";
 $conf{'djgpp'}=$test;
}

sub CheckGCC
{
 my $cc,$test;

 print 'Looking for a working gcc: ';
 $cc=@conf{'GCC'};
 if ($cc)
   {
    print "$cc (cached) OK\n";
    return $cc;
   }
 $cc=$ENV{'CC'};
 if (!length($cc))
   {
    $cc='gcc';
   }
 print "$cc ";
 $test='#include <stdio.h>
int main(void)
{
 printf("OK\n");
 return 0;
}
';
 $test=RunGCCTest($cc,'c',$test,'');
 if ($test ne "OK\n")
   {
    CreateCache();
    die 'Not working gcc found';
   }
 print "OK\n";
 $conf{'GCC'}=$cc;
 $cc;
}

sub CheckGCCcanXX
{
 my $cc=$_[0],$ret,$test;

 print "$cc can compile C++ code: ";
 $test='#include <iostream.h>
int main(void)
{
 cout << "OK" << endl;
 return 0;
}';
 $test=RunGCCTest($cc,'cc',$test,$stdcxx);
 if ($test eq "OK\n")
   {
    print "yes\n";
    $ret=1;
   }
 else
   {
    print "no\n";
    $ret=0;
   }
 $ret;
}


sub CheckGXX()
{
 if (@conf{'GXX'})
   {
    print "C++ compiler: @conf{'GXX'} (cached) OK\n";
    return @conf{'GXX'};
   }
 if (CheckGCCcanXX($GCC))
   {
    $GXX=$GCC;
   }
 else
   {
    # Test for a working g++
    $GXX=CheckGXX();
   }
 $conf{'GXX'}=$GXX;
}

sub CheckGXXReal()
{
 my $test;

 print 'Looking for the C++ compiler: ';
 $test='#include <iostream.h>
int main(void)
{
 cout << "OK" << endl;
 return 0;
}';
 $test=RunGCCTest($defaultCXX,'cc',$test,$stdcxx);
 if ($test ne "OK\n")
   {
    CreateCache();
    die('can not find it');
   }
 print "$defaultCXX\n";
 $defaultCXX;
}

sub LookForIntlSupport
{
 my $vNeed=$_[0],$test;

 print 'Checking for international support: ';
 if (@conf{'no-intl'} eq 'yes')
   {
    print "disabled by user request.\n";
    $conf{'intl'}='no';
    `cp include/nointl.h include/intl.h`;
    return;
   }
 if (@conf{'intl'} eq 'yes')
   {
    print "yes (cached)\n";
    return;
   }
 if (@conf{'intl'} eq 'no')
   {
    print "no (cached)\n";
    return;
   }
 $test='
#include <stdio.h>
#define FORCE_INTL_SUPPORT
#include <intl.h>
int main(void)
{
 printf("%s\n",_("OK"));
 return 0;
}';
 $test=RunGCCTest($GCC,'c',$test,'-Iinclude/ '.($OS eq 'dos' ? '-lintl' : ''));
 if ($test ne "OK\n")
   {
    print "not available or not usable, disabling.\n";
    $conf{'intl'}='no';
   }
 else
   {
    print "yes OK\n";
    $conf{'intl'}='yes';
   }
}

sub LookForKeysyms
{
 my $test;

 print 'Looking for X keysyms definitions: ';
 if (@conf{'HAVE_KEYSYMS'})
   {
    print "@conf{'HAVE_KEYSYMS'} (cached)\n";
    return;
   }
 $test='
#include <stdio.h>
#include <X11/keysym.h>
int main(void)
{
 if (XK_Return!=0)
    printf("OK\n");
 return 0;
}';
 $test=RunGCCTest($GCC,'c',$test,'');
 if ($test eq "OK\n")
   {
    $conf{'HAVE_KEYSYMS'}='yes';
    print " yes OK\n";
   }
 else
   {
    $conf{'HAVE_KEYSYMS'}='no';
    print " no, disabling enhanced support for Eterm 0.8.10+\n";
   }
}

sub LookForGPM
{
 my $vNeed=$_[0],$test;

 print 'Looking for gpm library: ';
 if (@conf{'gpm'})
   {
    print "@conf{'gpm'} (cached) OK\n";
    return;
   }
 $test='
#include <stdio.h>
#include <gpm.h>
int main(void)
{
 int version;
 printf("%s",Gpm_GetLibVersion(&version));
 return 0;
}';
 $test=RunGCCTest($GCC,'c',$test,'-lgpm');
 if (!length($test))
   {
    print "\nError: gpm library not found, please install gpm $vNeed or newer\n";
    print "Look in $ErrorLog for potential compile errors of the test\n";
    CreateCache();
    die "Missing library\n";
   }
 if (!CompareVersion($test,$vNeed))
   {
    print "$test, too old\n";
    print "Please upgrade your gpm library to version $vNeed or newer.\n";
    print "You can try with $test forcing the configure scripts.\n";
    CreateCache();
    die "Old library\n";
   }
 @conf{'gpm'}=$test;
 print "$test OK\n";
}

sub LookForNCurses
{
 my ($vNeed,$vReco)=@_,$test;

 print 'Looking for ncurses library: ';
 if (@conf{'ncurses'})
   {
    print "@conf{'ncurses'} (cached) OK\n";
    return;
   }
 $test='
#include <stdio.h>
#include <ncurses.h>
void dummy() {initscr();}
int main(void)
{
 printf(NCURSES_VERSION);
 return 0;
}';
 $test=RunGCCTest($GCC,'c',$test,'-lgpm');
 if (!length($test))
   {
    print "\nError: ncurses library not found, please install ncurses $vNeed or newer\n";
    print "Look in $ErrorLog for potential compile errors of the test\n";
    CreateCache();
    die "Missing library\n";
   }
 if (!CompareVersion($test,$vNeed))
   {
    print "$test, too old\n";
    print "Please upgrade your ncurses library to version $vNeed or newer.\n";
    print "You can try with $test forcing the configure scripts.\n";
    CreateCache();
    die "Old library\n";
   }
 print "$test OK\n";
 @conf{'ncurses'}=$test;
 if (!CompareVersion($test,$vReco))
   {
    print "Warning: $vReco version is recommended\n";
    $conf{'HAVE_DEFINE_KEY'}=0;
   }
 else
   {
    $conf{'HAVE_DEFINE_KEY'}=1;
   }
}

sub LookForPrefix
{
 my $test,$prefix;

 print 'Looking for prefix: ';
 $prefix=@conf{'prefix'};
 if ($prefix)
   {
    print "$prefix (cached/specified)\n";
    return;
   }
 if ($OS eq 'linux')
   {
    if (`which make`=~/(.*)\/bin\/make/)
      {
       $prefix=$1;
      }
    else
     {
      $prefix='/usr';
     }
   }
 else
   {
    $prefix=@ENV{'DJDIR'};
   }
 @conf{'prefix'}=$prefix;
 print "$prefix\n";
}

sub RunGCCTest
{
 my ($cc,$ext,$test,$switchs)=@_;
 my $file='test.'.$ext,$command,$label;

 replace($file,$test);
 $command="$cc -o test.exe $CFLAGS $file $switchs";
 #print "Running: $command\n";
 $label=$command.":\n";
 `echo $label >> $ErrorLog`;
 if ($OS eq 'dos')
   {
    `redir -ea $ErrorLog $command`;
   }
 else
   {
    `$command 2>> $ErrorLog`;
   }
 $test=`./test.exe`;
 unlink('test.o',$file,'test.exe');
 $test;
}


sub CompareVersion
{
 my ($actual,$needed)=@_;
 my $vact,$vneed;

 $actual=~/(\d+)\.(\d+)(\.(\d+))?/;
 $vact=$1*1000000+$2*1000+$4;
 $needed=~/(\d+)\.(\d+)(\.(\d+))?/;
 $vneed=$1*1000000+$2*1000+$4;
 #print "$vact v.s. $vneed\n";
 $vact>=$vneed;
}

sub GetCache
{
 my $val;

 #%conf={};
 if (open(FIL,'<configure.cache'))
   {
    while ($val=<FIL>)
      {
       if ($val=~/(.*) => (.*)\n/)
         {
          @conf{$1}=$2;
          #print "$1 => $2\n";
         }
       else
         {
          #print "No toma: ($val)";
         }
      }
    close(FIL);
   }
}

sub CreateCache
{
 my $i,$ff=1;

 if (open(FIL,'>configure.cache'))
   {
    foreach $i (%conf)
      {
       if ($ff)
         {
          print FIL ("$i => @conf{$i}\n");
          $ff=0;
         }
       else
         {
          $ff=1;
         }
      }
    close(FIL);
   }
}

sub GenerateMakefile
{
 my $text,$rep,$makeDir;

 print "Generating Makefile\n";
 $text=cat('Makefile.in');
 if (!$text)
   {
    CreateCache();
    die "Can't find Makefile.in!!\n";
   }
 $rep='static-lib';
 $rep.=' dynamic-lib' if ($OS eq 'linux');
 $text=~s/\@targets\@/$rep/g;
 $text=~s/\@OS\@/$OS/g;
 $text=~s/\@prefix\@/@conf{'prefix'}/g;

 $makeDir=$OS eq 'linux' ? 'linux' : 'djgpp';
 # Write target rules:
 $rep="static-lib: $makeDir/librhtv.a\n$makeDir/librhtv.a:\n\t\$(MAKE) -C ".$makeDir;
 $text=~s/\@target1_rule\@/$rep/g;
 if ($OS eq 'linux')
   {
    $rep="linuxso/librhtv.so.$Version";
    $rep="dynamic-lib: $rep\n$rep:\n\tcd linuxso; ./makemak.pl";
    $text=~s/\@target2_rule\@/$rep/g;
   }
 else
   {
    $text=~s/\@target2_rule\@//g;
   }

 # Write install stuff
 $rep= "install -d -m 0755 \$(prefix)/include/rhtvision\n";
 $rep.="\tinstall -m 0644 include/*.h \$(prefix)/include/rhtvision\n";
 $rep.="\tinstall -m 0755 $makeDir/librhtv.a \$(libdir)\n";
 if ($OS eq 'linux')
   {
    $rep.="\trm -f \$(libdir)/librhtv.so\n";
    $rep.="\trm -f \$(libdir)/librhtv.so.1\n";
    $rep.="\trm -f \$(libdir)/librhtv.so.$Version\n";
    $rep.="\tln -s \$(libdir)/librhtv.so.$Version \$(libdir)/librhtv.so\n";
    $rep.="\tln -s \$(libdir)/librhtv.so.$Version \$(libdir)/librhtv.so.1\n";
    $rep.="\tinstall -m 0755 linuxso/librhtv.so.$Version \$(libdir)\n";
    $rep.="\tstrip --strip-debug \$(libdir)/librhtv.so.$Version\n";
    $rep.="\tldconfig\n";
   }
 $text=~s/\@install_rule\@/$rep/g;

 replace('Makefile',$text);
}

#
# It fixes the Makefiles generated from the .gpr files
#
sub ModifyMakefiles
{
 my $a,$text;

 print 'Configuring makefiles: ';
 foreach $a (@_)
   {
    print "$a ";
    $text=cat($a);
    if ($text)
      {
       $text=~s/RHIDE_GCC=(.*)\n/RHIDE_GCC=$GCC\n/;
       $text=~s/RHIDE_GXX=(.*)\n/RHIDE_GXX=$GXX\n/;
       $text=~s/RHIDE_LD=(.*)\n/RHIDE_LD=$GXX\n/;
       $text=~s/RHIDE_OS_CFLAGS=(.*)\n/RHIDE_OS_CFLAGS=$CFLAGS\n/;
       $text=~s/RHIDE_OS_CXXFLAGS=(.*)\n/RHIDE_OS_CXXFLAGS=$CFLAGS\n/;
       replace($a,$text);
      }
   }
 print "\n";
}

#
# It creates the needed rhide.env files to configure RHIDE in case the user
# wants to use RHIDE after configuring.
#
sub CreateRHIDEenvs
{
 my $a,$text;

 print 'Configuring RHIDE: ';
 foreach $a (@_)
   {
    print "$a ";
    $text ="#\n# Automatically generated by configure script\n#\n\n";
    $text.="RHIDE_GCC=$GCC\n" unless ($GCC eq 'gcc');
    $text.="RHIDE_GXX=$GXX\n" unless ($GXX eq 'gcc');
    $text.="RHIDE_LD=$GXX\n"  unless ($GXX eq 'gcc');
    $text.="RHIDE_OS_CFLAGS=$CFLAGS\n";
    $text.="RHIDE_OS_CXXFLAGS=$CFLAGS\n";

    if ($text)
      {
       replace($a,$text);
      }
    else
      {
       unlink $a;
      }
   }
 print "\n";
}

sub CreateConfigH
{
 my $text="/* Generated automatically by the configure script */";

 print "Generating configuration header\n";

 $text.="\n\n/* ncurses 4.2 or better have define_key */\n";
 $text.='/*' unless (@conf{'HAVE_DEFINE_KEY'});
 $text.="#define HAVE_DEFINE_KEY";
 $text.='*/' unless (@conf{'HAVE_DEFINE_KEY'});

 $text.="\n\n/* The X11 keysyms are there */\n";
 $text.='/*' unless (@conf{'HAVE_KEYSYMS'} eq 'yes');
 $text.="#define HAVE_KEYSYMS";
 $text.='*/' unless (@conf{'HAVE_KEYSYMS'} eq 'yes');

 $text.="\n\n/* International support with gettext */\n";
 $text.='/*' unless (@conf{'intl'} eq 'yes');
 $text.="#define HAVE_INTL_SUPPORT";
 $text.='*/' unless (@conf{'intl'} eq 'yes');

 $text.="\n";

 replace('include/configtv.h',$text);
}

sub cat
{
 local $/;
 my $b;

 open(FIL,$_[0]) || return 0;
 $b=<FIL>;
 close(FIL);

 $b;
}

sub replace
{
 my $b=$_[1];

 open(FIL,">$_[0]") || return 0;
 print FIL ($b);
 close(FIL);
}
