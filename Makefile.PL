#!/usr/bin/perl -w
# Copyright 2007 Sebastian Stumpf <mail@sebastianstumpf.de>
# vim: set sw=4 ts=4
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'WWW::DirectUpload',
	VERSION_FROM	=> 'lib/WWW/DirectUpload.pm',
	PREREQ_PM		=> { 
		'LWP::UserAgent' => 0, 
		'HTTP::Request::Common' => 0,
		'HTML::TokeParser' => 0
	});


