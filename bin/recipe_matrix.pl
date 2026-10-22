#!/usr/bin/perl
# recipe_matrix.pl -- the third language over the circle: run recipe.sh's check and --prove-red under
#   every shell and every awk found on this machine, and require each pair to reach the verdicts the
#   second reader (recipe_check.py) reaches.  Born 2026-10-22, when busybox's sha256sum (no --status)
#   made a good seal read STALE under busybox sh, and only the second reader's DISAGREE showed it.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.  Tangled from RECIPE.org.
# usage: perl bin/recipe_matrix.pl [RECIPE]       one line per shell and awk: AGREE or DISAGREE, in words
#        perl bin/recipe_matrix.pl --prove-red    a planted broken awk and a planted reference must be caught
# Exit: 0 every pair agrees; 1 a pair disagrees or a prove-red fails; 2 NOT CHECKED (fewer than two pairs,
#   or no python3 for the reference).
use strict; use warnings;
use File::Basename qw(dirname); use File::Spec; use Cwd qw(abs_path);

my $bin = dirname(abs_path($0)); my $top = dirname($bin);
sub have { my ($c) = @_; my ($w) = split ' ', $c; for my $d (split /:/, $ENV{PATH} // '') { return 1 if -x "$d/$w" } 0 }
sub run { my ($env, @cmd) = @_; local %ENV = (%ENV, %$env);
  my $q = join ' ', map { my $x = $_; $x =~ s/'/'\\''/g; "'$x'" } @cmd;
  my $out = `$q 2>&1`; return ($? >> 8, $out) }
sub verdicts { my ($t) = @_; join "\n", grep { /^(SAME|DRIFT|MISSING|SEALED|STALE)\t/ } map { my @f = split /\t/; "$f[0]\t" . ($f[1] // '') } split /\n/, $t }

sub matrix {
  my ($recipe, $extra_awks, $reference_override) = @_;
  have('python3') or do { print "NOT CHECKED: no python3 for the reference reader\n"; return 2 };
  my ($rrc, $ref) = run({}, 'python3', '-I', "$bin/recipe_check.py", $recipe, dirname($recipe));
  $ref = verdicts($reference_override // $ref);
  my @shells = grep { have($_) } ('sh', 'dash', 'bash', 'busybox sh');
  my @awks = ((grep { have($_) } ('awk', 'gawk', 'mawk', 'original-awk', 'busybox awk')), @{ $extra_awks // [] });
  my ($pairs, $bad) = (0, 0);
  for my $sh (@shells) { for my $awk (@awks) {
    $pairs++;
    my ($crc, $cout) = run({ AWK => $awk }, (split ' ', $sh), "$bin/recipe.sh", 'check', $recipe);
    my ($prc, $pout) = run({ AWK => $awk }, (split ' ', $sh), "$bin/recipe.sh", '--prove-red');
    my $v = verdicts($cout); my ($count) = $pout =~ /prove-red: (\d+ of \d+)/;
    if ($v eq $ref && $prc == 0) { printf "AGREE\t%s with %s: the same verdicts as the second reader; prove-red %s\n", $sh, $awk, $count // '?' }
    else { $bad++; printf "DISAGREE\t%s with %s: %s\n", $sh, $awk,
      $v ne $ref ? "verdicts differ from the second reader's (" . join(', ', split /\n/, $v) . ")" : "prove-red exit $prc (" . ($count // 'no count') . ")" }
  } }
  if ($pairs < 2) { print "NOT CHECKED: only $pairs shell and awk pair on this machine\n"; return 2 }
  printf "recipe_matrix: %d of %d pairs agree\n", $pairs - $bad, $pairs;
  return $bad ? 1 : 0;
}

if (($ARGV[0] // '') eq '--prove-red') {
  my $recipe = File::Spec->catfile($top, 'RECIPE.org'); my ($n, $f) = (0, 0);
  my $tmp = File::Spec->catfile(File::Spec->tmpdir, "recipe_matrix.$$"); mkdir $tmp;
  my $fake = "$tmp/fake-awk"; open my $h, '>', $fake or die; print $h "#!/bin/sh\nexit 0\n"; close $h; chmod 0755, $fake;
  open my $save, '>&', \*STDOUT; close STDOUT; open STDOUT, '>', "$tmp/out" or die;
  my $rc1 = matrix($recipe, [$fake]); close STDOUT; open STDOUT, '>&', $save;
  my $o1 = do { local (@ARGV, $/) = "$tmp/out"; <> };
  $n++; if ($rc1 == 1 && $o1 =~ /^DISAGREE\t\S+(?: sh)? with \Q$fake\E/m) { print "caught: M1 an awk that does nothing is a DISAGREE, not a pass\n" } else { $f++; print "MISSED: M1\n" }
  close STDOUT; open STDOUT, '>', "$tmp/out2" or die;
  my $rc2 = matrix($recipe, [], "STALE\tAGENTS.md.sha256\n"); close STDOUT; open STDOUT, '>&', $save;
  my $o2 = do { local (@ARGV, $/) = "$tmp/out2"; <> };
  $n++; if ($rc2 == 1 && $o2 !~ /^AGREE/m) { print "caught: M2 a reference that differs makes every pair DISAGREE\n" } else { $f++; print "MISSED: M2\n" }
  unlink $fake, "$tmp/out", "$tmp/out2"; rmdir $tmp;
  printf "recipe_matrix prove-red: %d of %d planted faults caught\n", $n - $f, $n; exit($f ? 1 : 0);
}
exit matrix($ARGV[0] // File::Spec->catfile($top, 'RECIPE.org'));
