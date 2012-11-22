#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

B<analyze-twitter-dump.pl> - analyzes the twitter timeline dumps

=head1 DESCRIPTION

B<your_script> with a longer description, what the script does and for which
purpose it is intended.

=head1 SYNOPSIS

B<your_script> [--help|--man] [-c|--commandline] [-o|--optionstring I<with_parameters>]

=head1 OPTIONS

=over 8

=item Document all command line options, each with a separate C<=item>.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-c | --commandline>

Description what the B<--commandline> switch does.

=item B<-o | --optionstring> I<with_parameters>

Description what the B<--optionstring> parameter does, and what the user should
provide for the I<with_parameters> argument.

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;
use Data::Dumper;
use Date::Parse;

# variables for command line options
my $commandline;
my $optionstring;

# parse command line options
GetOptions(
	# display brief help
	'H|?|help|usage'	=> sub { HelpMessage(-verbose => 1) },
	
	# display complete help as man page
	'm|man'			=> sub { HelpMessage(-verbose => 2) },

	# command line switch (true or false)
	'c|commandline'		=> \$commandline,
	
	# a string parameter
	'o|optionstring=s'	=> \$optionstring
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

# check for mandatory command line options
#if ( !defined $optionstring ) {
#	pod2usage(-verbose => 1,
#		  -msg => '-o|--optionstring parameter is mandatory',
#		  -exitval => 1);
#}

# the fun begins here (i.e. your code :-) )

# $commandline is now set to true (1) if the -c or --commandline option was passed on the command line
# $optionstring now holds the argument that was passed after the -o or --optionstring parameter


my %tweets;
while(<>) {
	chomp;
	# extract tweet from input
	my($id,$tweet_time,$measure_time,$user,$retweets,$message)=split(/;/, $_, 6);

	# store general tweet data
	$tweets{$id}{'tweet_time'} = $tweet_time;
	$tweets{$id}{'user'} = $user;
	$tweets{$id}{'message'} = $message;

	# calculate time difference between tweet time and measure time
	my $tweet_time_epoch = str2time($tweet_time);
	my $measure_time_epoch = str2time($measure_time);
	my $since = $measure_time_epoch - $tweet_time_epoch;
	push @{$tweets{$id}{'retweets'}}, { since => $since, retweets => $retweets };
	$tweets{$id}{'measurements'} += 1;
}

#print Dumper(\%tweets);
foreach my $tweet (keys %tweets) {
	
	# find the max retweet to normalize
	my $max_retweets = 1;
	foreach my $retweets (@{$tweets{$tweet}{'retweets'}}) {
		$max_retweets = $max_retweets > $retweets->{'retweets'} ? $max_retweets : $retweets->{'retweets'};
	}

	# output
	foreach my $retweets (@{$tweets{$tweet}{'retweets'}}) {
		print $tweet . ";";
		print $tweets{$tweet}{'user'} . ";";
		print $retweets->{'since'} . ";" . $retweets->{'retweets'}/$max_retweets . "\n";
	}
}
