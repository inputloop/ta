#!/usr/bin/perl
# score-check.pl -- the second reader: re-derive the totals from the JSON itself, by its own code, and
#   compare with score.awk's summary.  Prints AGREE or DISAGREE per model+cond; exit 0 only if all agree.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.
# usage: perl score-check.pl cases.jsonl results.jsonl awk-summary.tsv
use strict; use warnings; use JSON::PP;
my ($cases, $results, $summary) = @ARGV;
die "usage: score-check.pl CASES RESULTS SUMMARY\n" unless defined $summary;
my $J = JSON::PP->new;
my %want;
open my $c, '<:encoding(UTF-8)', $cases or die "$cases: $!";
while (<$c>) { next unless /\S/; my $o = $J->decode($_); $want{$o->{id}} = $o->{verdict}; }
sub read_verdict {    # my own reading, not a port of the awk: scan the first line's words in order
  my ($line) = @_; $line = uc($line // ''); $line =~ s/[^A-Z]+/ /g;
  my @w = split ' ', $line;
  for my $i (0 .. $#w) { return 'NOT CHECKED' if $w[$i] eq 'NOT' && ($w[$i+1] // '') eq 'CHECKED'; }
  for (@w) { return 'RED' if $_ eq 'RED'; }
  for (@w) { return 'OK' if $_ eq 'OK'; }
  return 'UNPARSED';
}
my (%tot, %right);
open my $r, '<:encoding(UTF-8)', $results or die "$results: $!";
while (<$r>) {
  next unless /\S/; my $o = $J->decode($_);
  my ($first) = grep { /\S/ } split /\n/, ($o->{answer} // '');   # the first non-blank line, as score.awk's feed
  my $k = "$o->{model}\t$o->{cond}";
  $tot{$k}++; $right{$k}++ if read_verdict($first) eq ($want{$o->{id}} // '?');
}
my $bad = 0; my %seen;
open my $s, '<:encoding(UTF-8)', $summary or die "$summary: $!";
while (<$s>) {
  chomp; next if /^ROW\t/ || !/\S/;
  my ($m, $cd, $t, $rt) = split /\t/;
  my $k = "$m\t$cd"; $seen{$k} = 1;
  my ($pt, $pr) = ($tot{$k} // 0, $right{$k} // 0);
  if ($pt == $t && $pr == $rt) { print "AGREE\t$k\t$pr/$pt\n" }
  else { print "DISAGREE\t$k\tawk $rt/$t perl $pr/$pt\n"; $bad = 1 }
}
for my $k (sort keys %tot) { next if $seen{$k}; print "DISAGREE\t$k\tmissing from the awk summary\n"; $bad = 1 }
print "NOT CHECKED: no answers to compare\n" and exit 2 unless %tot;
exit $bad;
