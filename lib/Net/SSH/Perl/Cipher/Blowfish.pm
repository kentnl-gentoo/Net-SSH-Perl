# $Id: Blowfish.pm,v 1.7 2001/02/22 00:03:09 btrott Exp $

package Net::SSH::Perl::Cipher::Blowfish;

use strict;
use Carp qw/croak/;

use Net::SSH::Perl::Cipher;
use base qw/Net::SSH::Perl::Cipher/;

use Net::SSH::Perl::Cipher::CBC;

use vars qw/$BF_CLASS/;
BEGIN {
    my @err;
    for my $mod (qw( Crypt::Blowfish Crypt::Blowfish_PP )) {
        eval "use $mod;";
        $BF_CLASS = $mod, last unless $@;
        push @err, $@;
    }
    die "Failed to load Crypt::Blowfish and Crypt::Blowfish_PP: @err"
        unless $BF_CLASS;
}

sub new {
    my $class = shift;
    my $key = shift;
    my $blow = $BF_CLASS->new($key);
    my $cbc = Net::SSH::Perl::Cipher::CBC->new($blow);
    bless { cbc => $cbc }, $class;
}

sub encrypt {
    my($ciph, $text) = @_;
    _swap_bytes($ciph->{cbc}->encrypt(_swap_bytes($text)));
}

sub decrypt {
    my($ciph, $text) = @_;
    _swap_bytes($ciph->{cbc}->decrypt(_swap_bytes($text)));
}

sub _swap_bytes {
    my $str = $_[0];
    $str =~ s/(.{4})/reverse $1/sge;
    $str;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::Blowfish - Wrapper for SSH Blowfish support

=head1 SYNOPSIS

    use Net::SSH::Cipher;
    my $cipher = Net::SSH::Cipher->new('Blowfish', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::Blowfish> provides Blowfish encryption
support for I<Net::SSH::Perl>. To do so it wraps around either
I<Crypt::Blowfish> or I<Crypt::Blowfish_PP>; the former is a
C/XS implementation of the blowfish algorithm, and the latter is
a Perl implementation. I<Net::SSH::Perl::Cipher::Blowfish> prefers
to use I<Crypt::Blowfish>, because it's faster, so we try to load
that first. If it fails, we fall back to I<Crypt::Blowfish_PP>.
Note that, when using I<Crypt::Blowfish_PP>, you'll experience
a very noticeable decrease in performance.

The blowfish used here is in CBC filter mode with a key length
of 32 bytes.

SSH adds an extra wrinkle with respect to its blowfish algorithm:
before and after encryption/decryption, we have to swap the bytes
in the string to be encrypted/decrypted. The byte-swapping is done
four bytes at a time, and within each of those four-byte blocks
we reverse the bytes. So, for example, the string C<foobarba>
turns into C<boofabra>. We swap the bytes in this manner in the
string before we encrypt/decrypt it, and swap the
encrypted/decrypted string again when we get it back.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
