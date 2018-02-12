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

package NCG;

use NCG::SiteDB;

# static variables used for path configuration variable in metric definitions
# in config generation (ConfigGen module) they are replaced by:
# $USER1$
$NCG_PROBES_PATH_NAGIOS = '__NAGIOS_PATH__';
# WLCG_PROBES_DIR
$NCG_PROBES_PATH_GRIDMON = '__GRIDMON_PATH__';
# WLCG_PLUGINS_DIR
$NCG_PLUGINS_PATH_GRIDMON = '__GRIDMON_PLUGINS_PATH__';

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self = shift || {};

    if ( defined $self->{SITEDB}) {
        $self->{SITENAME} = $self->{SITEDB}->siteName if (! defined $self->{SITENAME});
    }

    $self->{DEFAULT_HTTP_TIMEOUT} = 180;

    bless ($self, $class);
    $self;
}

sub error($) {
    my $self = shift;
    my $msg = shift;
    print "ERROR: $msg\n";
    1;
}

sub warning($) {
    my $self = shift;
    my $msg = shift;
    print "WARNING: $msg\n" if ($self->{WARNING});
    1;
}

sub debug($) {
    my $self = shift;
    my $msg = shift;
    print "DEBUG: $msg\n" if ($self->{DEBUG});
    1;
}

sub verbose($) {
    my $self = shift;
    my $msg = shift;
    print "$msg\n" if (exists $self->{VERBOSE});
    1;
}

sub debugSub {
    my $self = shift;
    return 1 if (!$self->{DEBUG});

    my $sub = ( caller(1) )[3];
    my $args = "";
    foreach my $arg (@_) {
        if ($arg) {
            $args .= "$arg ";
        } else {
            $args .= "undef ";
        }
    }
    chop $args;
    print "DEBUG: in $sub with args: $args\n";
    
    1;
}

sub getData
{
    my $self = shift;
    $self->error("Method getData not implemented!");
}

sub _addRecurseDirs {
    my $self = shift;
    my $filelist = shift;
    my $path = shift;

    $path .= '/' if($path !~ /\/$/);

    foreach my $eachFile (glob($path.'*')) {
        if( -d $eachFile) {
            $self->_addRecurseDirs ($filelist, $eachFile);
        } elsif ( -f $eachFile) {
            push @$filelist, $eachFile;
        }
    }
}

# Crypt-SSLeay cancels alarm so we need to store it
sub safeHTTPSCall {
    my $self = shift;
    my $ua = shift;
    my $req = shift;

    my $remainingTime = alarm(0);
    my $timeNow = time();

    my $res = $ua->request($req);

    $remainingTime = $remainingTime - (time() - $timeNow);
    $remainingTime = 1 if ($remainingTime <= 0);
    alarm($remainingTime);

    return $res;
}

=head1 NAME

NCG

=head1 DESCRIPTION

The NCG module is top level class for all modules responsible for
extracting information about grid site, services &
local/remote probes used for monitoring.

Main method for invoking module's functionality is getData. Each 
module must have this method implemented.

NCG contains helper functions useful to extending modules: logging,
port and host checking, etc.

=head1 SYNOPSIS

  use NCG;

=cut

=head1 METHODS

=over

=item C<new>

  $dbh = NCG->new( $attr );

Creates new NCG instance.

=item C<checkPing>

  $res = $ncg->checkPing($host);

Method checks if host is reachable with ICMP.

=item C<checkTcp>

  $res = $ncg->checkTcp($host, $port);

Method checks if TCP port on specified host is opened.

=item C<error>

  $res = $ncg->error($msg);

Method prints error message. This method is used for logging purposes.

=item C<warning>

  $res = $ncg->warning($msg);

Method prints warning message. This method is used for logging purposes.

=item C<verbose>

  $res = $ncg->verbose($msg);

Method prints message if verbose is switched on. This method is used
for logging purposes.

=back

=head1 SEE ALSO

=cut


1;
