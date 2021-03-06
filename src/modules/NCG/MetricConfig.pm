#!/usr/bin/perl -w
#
# Nagios configuration generator (WLCG probe based)
# Copyright (c) 2007 Emir Imamagic
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package NCG::MetricConfig;

use JSON;
use strict;
use warnings;
use NCG;
use vars qw(@ISA);

@ISA=("NCG");

my $DEFAULT_METRIC_CONFIG_FILE = "/etc/ncg-metric-config.conf";
my $DEFAULT_METRIC_CONFIG_DIR = "/etc/ncg-metric-config.d/";

sub new : method {
    my ($proto, $data) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($data);
    
    $self->{METRIC_CONFIG_FILE} = $DEFAULT_METRIC_CONFIG_FILE
        unless ( defined $self->{METRIC_CONFIG_FILE} );
    $self->{METRIC_CONFIG_DIR} = $DEFAULT_METRIC_CONFIG_DIR
        unless ( defined $self->{METRIC_CONFIG_DIR} );
    
    if (! -f $self->{METRIC_CONFIG_FILE})
    {
        $self->error("Can't find static file!");
        undef $self;
        return 0;
    }

    if (! -d $self->{METRIC_CONFIG_DIR})
    {
        $self->error("Can't find static directory!");
        undef $self;
        return 0;
    }
    my $filelist = [];
    $self->_addRecurseDirs($filelist, $self->{METRIC_CONFIG_DIR});
    foreach my $file (@$filelist) {
        $self->{DB_FILES}->{$file} = 1 if ($file =~ /\.conf$/);
    }
   
    $self;
}

sub _loadMetrics {
    my $self = shift;
    my $file = shift;
    my $result;
    my $fileHndl;
    my $jsonRef;

    unless (open ($fileHndl, $file)) {
        $self->error("Cannot open metric config file $file!");
	return;
    }
    $result = join ("", <$fileHndl>);
    eval {
        $jsonRef = from_json($result);
    };
    if ($@) {
        $self->error("Error parsing JSON response in file $file: ".$@);
        return;
    }
    foreach my $metric (keys %{$jsonRef}) {
        if (exists $self->{METRIC_CONFIG}->{$metric}) {
            foreach my $attr (keys %{$jsonRef->{$metric}}) {
                if ( ref $jsonRef->{$metric}->{$attr} eq "HASH" ) {
                    foreach my $attr2 (keys %{$jsonRef->{$metric}->{$attr}}) {
                        $self->{METRIC_CONFIG}->{$metric}->{$attr}->{$attr2} = $jsonRef->{$metric}->{$attr}->{$attr2};
                    }
                } else {
                    $self->{METRIC_CONFIG}->{$metric}->{$attr} = $jsonRef->{$metric}->{$attr};
                }
            }
        } else {
            $self->{METRIC_CONFIG}->{$metric} = {%{$jsonRef->{$metric}}}
        }
    }
    unless (close ($fileHndl)) {
        $self->error("Cannot close metric config file $file!");
    }
}


sub getData {
    my $self = shift;
    my $fileHndl;
    $self->{METRIC_CONFIG} = {};
    
    $self->_loadMetrics($self->{METRIC_CONFIG_FILE});

    foreach my $file (keys %{$self->{DB_FILES}}) {
        $self->_loadMetrics($file);
    }
}

=head1 NAME

NCG::LocalMetrics

=head1 DESCRIPTION

The NCG::LocalMetrics module is abstract class for extracting
information about local metrics which are available for each host.
Each module extending NCG::LocalMetrics must implement method
getMetrics.

=head1 SYNOPSIS

  use NCG::LocalMetrics;
  $ncg = NCG::LocalMetrics->new( $attr );
  $ncg->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $dbh = NCG::LocalMetrics->new( $attr );

Creates new NCG::LocalMetrics instance.

=item C<getData>

  $ncg->getData ();

Abstract method for gathering metric information.

=back

=head1 SEE ALSO

=cut

1;
