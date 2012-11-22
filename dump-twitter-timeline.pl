#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

B<dump-twitter-timeline.pl> - dump a twitter timeline into CSV format

=head1 DESCRIPTION

B<dump-twitter-timeline.pl> dumps a twitter timeline into a CSV format. The output includes
the tweet itself, the tweet ID and some meta data. Most importantly, it contains the retweet count,
which I need to investigate retweet behaviours.

=head1 SYNOPSIS

B<dump-twitter-timeline.pl> [--help|--man] --consumer-secret I<CONSUMER_SECRET> --access-token-secret I<ACCESS_TOKEN_SECRET>

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-cs | --consumer-secret> I<CONSUMER_SECRET>

The Twitter API consumer secret. Get one at I<https://dev.twitter.com>.

=item B<-ats | --access-token-secret> I<ACCESS_TOKEN_SECRET>

The Twitter API access token secret. Get one at I<https://dev.twitter.com>.

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;
use Net::Twitter;
use Data::Dumper;
use Scalar::Util 'blessed';
use POSIX qw(strftime);
use utf8;
binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";

# variables for command line options
my $consumer_key="AE5GtcAiVfxe7QJALQ1pw";
my $consumer_secret;
my $access_token="45557338-2TvQadkk1AxZc4xCMWafG8bETJ0GEFpG0aj1drR7k";
my $access_token_secret;

# parse command line options
GetOptions(
	'H|?|help|usage'		=> sub { HelpMessage(-verbose => 1) },
	'm|man'				=> sub { HelpMessage(-verbose => 2) },
	'cs|consumer-secret=s'		=> \$consumer_secret,
	'ats|access-token-secret=s'	=> \$access_token_secret,
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

# check for mandatory command line options
if ( !defined $consumer_secret || !defined $access_token_secret ) {
	pod2usage(-verbose => 1,
		  -msg => '--consumer-secret and --access-token-secret parameter are mandatory',
		  -exitval => 1);
}

my $nt = Net::Twitter->new(
	traits   => [qw/OAuth API::REST/],
	consumer_key        => $consumer_key,
	consumer_secret     => $consumer_secret,
	access_token        => $access_token,
	access_token_secret => $access_token_secret,
);

eval {
	my $max_id;
	my $num_fetched=0;
	do {
		$num_fetched=0;
		my $statuses;
		my $fetchtime;
		$fetchtime = strftime "%a %b %e %H:%M:%S %z %Y", localtime(time);
		if (defined $max_id) {
			$statuses = $nt->home_timeline({ count => 800, max_id => $max_id-1 });
		} else {
			$statuses = $nt->home_timeline({ count => 800 });
		}
		for my $status (@$statuses) {
			if (defined $max_id) {
				$max_id = $status->{id} < $max_id ? $status->{id} : $max_id;
			} else {
				$max_id = $status->{id};
			}
			$num_fetched += 1;
			print "$status->{id};";
			print "$status->{created_at};";
			print "$fetchtime;";
			print "$status->{user}{screen_name};";
			print "$status->{retweet_count};";
			print join(" ", split(/\n/,$status->{text})).";";	# replace newlines by one space
			print "\n";
		}
	} while($num_fetched > 0);
};
if ( my $err = $@ ) {
	die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	warn "HTTP Response Code: ", $err->code, "\n",
	     "HTTP Message......: ", $err->message, "\n",
	     "Twitter error.....: ", $err->error, "\n";
}
