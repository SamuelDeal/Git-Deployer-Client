#!/usr/bin/perl

###############################################################################
# Script Name:	Git Deployer Client
# Author: 	Guillaume Seigneuret
# Date: 	04.01.2012
# Last mod	04.01.2012
# Version:	1.0b
# 
# Usage:	gdc <projet> <branch>
# 
# Usage domain: To be executed by git hook (post-update script) 
# 
# Args :	Project name AND Branch name are mandatory if the environmental
# 		variable SSH_ORIGINAL_COMMAND is not set.	
#
# Config: 	Every parameters must be described in the config file
# 
# Config file:	Must be the name of the script (with .config or rc extension), 
# 		located in /etc or the same path as the script
# 
#   Copyright (C) 2012 Guillaume Seigneuret (Omega Cube)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>		 
###############################################################################

use strict;
use warnings;
use v5.22.1;

use IO::Socket;
use Module::Load;
use Data::Dumper;
use IO::Handle;
use Getopt::Long;
use Pod::Usage;

use constant DEFAULT_PORT => 32337;
use constant DEFAULT_SERVER => 'localhost';


my $config_module = 0;
eval {
    load Config::Auto;
    $config_module = 1;
    1;
} 
or do {
    print "WARNING: no config module installed\n";
};


sub main {
    my $help = 0;
    my $man = 0;
    GetOptions(
        'm|man!'          => \$help,
        'h|?|help!'       => \$man,
    ) or do {
        return pod2usage(-verbose => 1, -exitval => 1)
    };
    return pod2usage(-verbose => 1, -exitval => 0) if $help;
    return pod2usage(-verbose => 2, -exitval => 0) if $man;

    if((not defined($ARGV[1]) or not defined $ENV{SSH_ORIGINAL_COMMAND}) and not defined($ARGV[0])) {
        die("Please, provide the project name and the branch as argument\n");
    }

	my $project_name = "";
	my $project = "";
	$project_name = $ARGV[1] if defined $ARGV[1];
    
	$project_name = "$1.git" if defined($ENV{SSH_ORIGINAL_COMMAND}) and $ENV{SSH_ORIGINAL_COMMAND} =~ /git-receive-pack '(.*)'/;
	$project_name = $1 if defined($ENV{SSH_ORIGINAL_COMMAND}) and $ENV{SSH_ORIGINAL_COMMAND} =~ /'(.*\.git)/;
	$project = $1 if $project_name =~ /.*\/(.*)\.git/;
	$project = $1 if $project_name =~ /(.*)\.git/ and $project eq "";
	chomp(my $branch = $ARGV[0]);

	$branch = $1 if $branch =~ /\/(\w+)$/;

    run($project_name, $branch);
}


sub run {
    my ($project, $branch) = @_;

    my @addresses   = get_config($project, $branch);
    foreach my $address (@addresses) {
        con_and_command($address, "Project: $project Branch: $branch");
    }
}


sub con_and_command {
	my ($address, $string) = @_;

    $| =1;

    print $string."\r\n";
	my $socket = IO::Socket::INET->new(Proto    => "tcp",
	                                   PeerAddr => $address,
	                                  )
	or die "Connexion to $address failed : $@\n";
	
	while(my $response=<$socket>){
        if(substr($response, 0, 1) ne "\b") {
            print "\n";
        }
        print substr($response, 0, -1);
        STDOUT->flush();
		
		if($response =~ /please make your request/){
            STDOUT->flush();
			print $socket $string."\r\n";
            $socket->flush();
		}

		#print $socket "quit\n\r";	
	}
    shutdown($socket, 2);
	close($socket);
}



sub get_config {
    my ($project, $branch) = @_;

    my $config = undef;
    if($config_module) {
        eval {
            my $conf_parser = Config::Auto->new(format => 'ini');
            $config = $conf_parser->parse();
            1;
        }
        or die "invalid configuration: ".$@;
    }

    $project =~ s/\.git$//;

    if(defined($config)) {
        foreach my $pattern (reverse(keys(%{$config}))) {
            my ($project_pattern, $branch_pattern) = trim(split(/\//, $pattern));
            $branch_pattern = ".*" unless defined $branch_pattern;
            $project_pattern = '^'.$project_pattern.'$';
            $branch_pattern = '^'.$branch_pattern.'$';

            next unless $project =~ $project_pattern;
            next unless $branch =~ $branch_pattern;

            return () if exists($config->{$pattern}->{"ignore"});

            my @addresses = trim(split(/;/, $config->{$pattern}->{"address"}));
            return map { $_ =~ /:/ ? $_ : $_.":".DEFAULT_PORT } @addresses;
        }
        print "Warning: $project/$branch not configured\n";
        return (DEFAULT_SERVER.':'.DEFAULT_PORT);
    }
    else {
        return (DEFAULT_SERVER.':'.DEFAULT_PORT);
    }
}


sub trim {
    my @out = @_;
    for(@out) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}

main();

__END__


=head1 NAME

GDC.pl - Git Deployer Client

=head1 SYNOPSIS

GDC.pl PROJECT BRANCH
 Options:
   --help, -h           brief help message
   --man, -m            full documentation

   PROJECT              the git repository name
   BRANCH               the branch updated

=head1 OPTIONS
=over 8
=item B<--help>
Print a brief help message and exits.

=item B<-man>
Prints the manual page and exits.

=back
=head1 DESCRIPTION
B<This program> will read the given input file(s) and do something
useful with the contents thereof.
=cut


