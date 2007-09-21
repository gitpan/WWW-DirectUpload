#!/usr/bin/perl -w
# Copyright 2007 Sebastian Stumpf <mail@sebastianstumpf.de>
# vim: set sw=4 ts=4
package WWW::DirectUpload;
use strict;
use warnings;
use base qw(LWP::UserAgent);
use HTTP::Request::Common;
use HTML::TokeParser;
use Carp;
use Data::Dumper;

our $VERSION = '0.01';

sub new
{
	my $class = shift;
	my $self = { @_ };

	$self->{'Agent'}	||= 'Mozilla/5.0';

	$self->{'Allowed'}	||= [ qw(jpg jpeg gif png) ];
	$self->{'MaxSize'}	||= 2097152;
	$self->{'Action'}	||= 'http://www.directupload.com/index.html';

	bless $self, $class;

	$self->agent($self->{'Agent'});
	$self->{'Files'} = [];

	return $self;
}

sub files
{
	my $self = shift;
	my @files = @_;

	foreach my $ref (@files)
	{
		croak("Could not access file: $!") unless -f $ref->{'file'};
		croak("Filetype not allowed!") unless grep { $ref->{'file'} =~ m/\.$_$/i } @{ $self->{'Allowed'} };
		croak("Filesize is to big!") if (stat($ref->{'file'}))[7] > $self->{'MaxSize'};

		push @{ $self->{'Files'} }, $ref;
	}
}

sub upload
{
	my $self = shift;
	croak("No files to upload...") unless @{ $self->{'Files'} };
	my @ret = ();

	foreach my $ref (@{ $self->{'Files'} })
	{
		my $req = POST($self->{'Action'},
				Content_Type	=> 'form-data',
				Content			=> [ submitme	=> 1,
									 submit		=> 'Upload Image',
									 imgdesc	=> $ref->{'tags'},
									 imgfile	=> [ $ref->{'file'} ] ]);

		my $post = $self->request($req);
		croak("Upload failed: " . $post->status_line()) unless $post->is_success();

		my $doc = $post->content();
		my $parser = HTML::TokeParser->new(\$doc);

		while(my $t = $parser->get_token())
		{
			next unless $t->[0] eq 'T' && $t->[1];
			next unless $t->[1] =~ m#^http://directupload\.com/showpic-\d+\..+#;
			push @ret, $t->[1];
		}
	}

	@ret = map { m#^(.+)showpic-(.+)#; { thumb => "$1thumb-$2", image => "$1showoriginal-$2" } } @ret;
	return @ret;
}

return 1;
__END__

=head1 NAME

WWW::DirectUpload - Perl module for uploading files to directupload.com

=head1 SYNOPSIS

  use WWW::DirectUpload;
  my $du = WWW::DirectUpload->new();
  $du->files(@files);
  $du->upload();

=head1 DESCRIPTION

This module allows you to upload files to directupload.com using Perl. Its 
upload() method will return you the path to the original image and its thumbnail.

WWW::DirectUpload uses LWP::UserAgent as its base class. So you can use all methods
from LWP::UserAgent on WWW::DirectUpload. This allows you to handle your proxies
directly via LWP.

=head1 Methods

=over 4

=item * $du->files(files)

Use this method to tell WWW::DirectUpload which files you want to upload. A typical
list would look like @files = ({file=>"pic1.jpg", tags=>""},{file=>"pic2.png", tags=>"those are my tags"});

=item * $du->upload()

This method will upload your files. It returns a list of hashrefs of the given files
in the order you've passed them to files(). A typical return value would look like
({thumb=>"...",image=>"..."},{thumb=>"...",image=>"..."})

=back

=head1 AUTHOR

Sebastian Stumpf E<lt>sepp@perlhacker.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Sebastian Stumpf.   All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

LWP::UserAgent(3), HTTP::Request::Common(3).

=cut
