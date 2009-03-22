#!/usr/bin/perl -w

my @acs = glob("*.ac");

foreach my $ac (@acs)
{
  my $tmp = $ac . ".tmp";
  system("cp $ac $tmp");
  open(AC, $ac) || die("unable to open $ac");
  open(TMPAC, ">$tmp") || die("Unable to open $tmp");

  foreach (<AC>)
  {
    if (/MATERIAL "metal"/)
    {
      # Metal
      print TMPAC "MATERIAL \"metal\" rgb 0 0 0 amb 0.1 0.1 0.12 emis 0 0 0 spec 0.2 0.2 0.2 shi 10 trans 0\n";
    }
    elsif (/MATERIAL "face"/)
    {
      # A red-flood lit instrument face
      print TMPAC "MATERIAL \"face\" rgb 0 0 0 amb 1.0 1.0 1.0 emis 0.3 0 0 spec 0 0 0 shi 10 trans 0\n";
    }
    elsif (/MATERIAL "unlitface"/)
    {
      # An unlit face
      print TMPAC "MATERIAL \"face\" rgb 0 0 0 amb 1.0 1.0 1.0 emis 0 0 0 spec 0 0 0 shi 10 trans 0\n";
    }
    else
    {
      print TMPAC $_;
    }
  }

  close(AC);
  close(TMPAC);
  system("mv $tmp $ac");
}