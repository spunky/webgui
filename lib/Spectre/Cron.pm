package Spectre::Cron;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2006 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use DateTime;
use HTTP::Request::Common;
use HTTP::Cookies;
use POE qw(Component::Client::HTTP);
use WebGUI::Session;
use WebGUI::Workflow::Cron;

#-------------------------------------------------------------------

=head2 _start ( )

Initializes the scheduler.

=cut

sub _start {
        my ($kernel, $self, $publicEvents) = @_[ KERNEL, OBJECT, ARG0 ];
	$self->debug("Starting Spectre scheduler.");
        my $serviceName = "cron";
        $kernel->alias_set($serviceName);
        $kernel->call( IKC => publish => $serviceName, $publicEvents );
	$self->debug("Loading the schedules from all the sites.");
	my $configs = WebGUI::Config->readAllConfigs($self->config->getWebguiRoot);
	foreach my $config (keys %{$configs}) {
		next if $config =~ m/^demo/;
		$kernel->yield("loadSchedule", $config);
	}
        $kernel->yield("checkSchedules");
}

#-------------------------------------------------------------------

=head2 _stop ( )

Gracefully shuts down the scheduler.

=cut

sub _stop {
	my ($kernel, $self) = @_[KERNEL, OBJECT];
	$self->debug("Stopping the scheduler.");
	undef $self;
}

#-------------------------------------------------------------------

=head2 addJob ( params ) 

Adds a job to the cron monitoring queue.

=head3 params

A hash reference containing data about the job.

=head4 taskId

The unique id for the cron job.

=head4 sitename

The sitename that the job belongs to.

=head4 config

The name of the config file of the site that the job belongs to.

=head4 enabled

A boolean indicating whether the job is enabled or not.

=head4 minuteOfHour

Part of the schedule.

=head4 hourOfDay

Part of the schedule.

=head4 dayOfMonth

Part of the schedule.

=head4 monthOfYear

Part of the schedule.

=head4 dayOfWeek

Part of the schedule.

=head4 runOnce

A boolean indicating whether this cron should be executed more than once.

=head4 workflowId

The ID of the workflow that should be kicked off when the time is right.

=head4 className

The class name of the object to be created to be passed in to the workflow.

=head4 methodName

THe method name of the object to be created to be passed in to the workflow.

=head4 parameters

The parameters of the object to be created to be passed in to the workflow.

=head4 priority

An integer (1,2,3) that determines what priority the workflow should be executed at.

=cut

sub addJob {
	my ($self, $params) = @_[OBJECT, ARG0];
	return 0 unless ($params->{enabled});
	my $id = $params->{config}."-".$params->{taskId};
	$self->debug("Adding schedule ".$params->{taskId}." to the queue.");
	$params->{schedule} = join(" ", $params->{minuteOfHour}, $params->{hourOfDay}, $params->{dayOfMonth}, $params->{monthOfYear}, $params->{dayOfWeek});
	$self->{_jobs}{$id} = $params;
}

#-------------------------------------------------------------------

=head2 checkSchedule ( jobId, now )

Compares a schedule with the current time and kicks off an event if necessary. This method should only ever need to be called by checkSchedules().

=head3 jobId

A jobId definition created through the addJob() method.

=head3 now

A DateTime object representing the time to compare the schedule with.

=cut

sub checkSchedule {
	my ($kernel, $self, $jobId, $now) = @_[KERNEL, OBJECT, ARG0, ARG1];
	$self->debug("Checking schedule ".$jobId." against the current time.");
	my $job = $self->getJob($jobId);
	if ($self->checkSegment($now->minute, $job->{minuteOfHour}, [0..59])
		&& $self->checkSegment($now->hour, $job->{hourOfDay}, [0..23])
		&& $self->checkSegment($now->day, $job->{dayOfMonth}, [1..31])
		&& $self->checkSegment($now->month, $job->{monthOfYear}, [1..12])
		&& $self->checkSegment($now->dow, $job->{dayOfWeek}, [0..6]) ) {
		$self->debug("It's time to run ".$jobId.". Creating workflow instance.");
		$kernel->yield("runJob",$jobId);
	}
}

#-------------------------------------------------------------------

=head2 checkSchedules ( ) 

Checks all the schedules of the jobs in the queue and triggers a workflow if a schedule matches.

=cut

sub checkSchedules {
	my ($kernel, $self) = @_[KERNEL, OBJECT];
	$self->debug("Checking schedules against current time.");
	my $now = DateTime->from_epoch(epoch=>time());
	foreach my $id (keys %{$self->{_jobs}}) {
		$kernel->yield("checkSchedule", $id, $now)
	}
	$kernel->delay_set("checkSchedules",60);
}

#-------------------------------------------------------------------

=head2 checkSegment ( current, pattern, range )

Checks a crontab schedule segment against a current time segment.

=cut

sub checkSegment {
	# borrowed from Set::Crontab on CPAN
	my $self = shift;
        my (@list, @and, @not);
        my ($now, $spec, $range) = @_;
        # 1,2-4,*/3,!13,>9,<15
        foreach (split /,/, $spec) {
                my @pick;
                my $step = $1 if s#/(\d+)$##;
                # 0+"01" == 1
                if    (/^(\d+)$/)       { push @pick, 0+$1;          }
                elsif (/^\*$/)          { push @pick, @$range;       }
                elsif (/^(\d+)-(\d+)$/) { push @pick, 0+$1..0+$2;    }
                elsif (/^!(\d+)$/)      { push @not,  "\$_ != 0+$1"; }
                elsif (/^([<>])(\d+)$/) { push @and,  "\$_ $1 0+$2"; }
                if ($step) {
                        my $i;
                        @pick = grep { defined $_ if $i++ % $step == 0 } @pick;
                }
                push @list, @pick;
        }
        if (@and) {
                my $and = join q{ && }, @and;
                push @list, grep { defined $_ if eval $and } @$range;
        }
        if (@not) {
                my $not = join q{ && }, @not;
                @list = grep { defined $_ if eval $not } (@list ? @list : @$range);
        }
        my $matches = {map {$_ => 1} @list};
        return exists $matches->{$now};
}

#-------------------------------------------------------------------

=head2 config 

Returns a reference to the config object.

=cut 

sub config {
	my $self = shift;
	return $self->{_config};
}

#-------------------------------------------------------------------

=head2 debug ( output )

Prints out debug information if debug is enabled.

=head3 output

The debug message to be printed if debug is enabled.

=cut 

sub debug {
	my $self = shift;
	my $output = shift;
	if ($self->{_debug}) {
		print "CRON: ".$output."\n";
	}
	$self->getLogger->debug("CRON: ".$output);
}

#-------------------------------------------------------------------

=head2 deleteJob ( params ) 

Removes a job from the monitoring queue.

=head3 params

A hash reference containing the info needed to delete this job.

=head4 id

The unique ID for this job.

=cut

sub deleteJob {
	my ($self, $id) = @_[OBJECT, ARG0];
	$self->debug("Deleting schedule ".$id." from queue.");
	delete $self->{_errorCount}{$id};
	delete $self->{_jobs}{$id};
}

#-------------------------------------------------------------------

=head2 error ( output )

Prints out error information if debug is enabled.

=head3 output

The error message to be printed if debug is enabled.

=cut 

sub error {
	my $self = shift;
	my $output = shift;
	if ($self->{_debug}) {
		print "CRON: [Error] ".$output."\n";
	}
	$self->getLogger->error("CRON: ".$output);
}

#-------------------------------------------------------------------

=head2 getJob ( id ) 

Returns a hash reference to a job.

=head3 id

The unique id of the job to fetch.

=cut

sub getJob {
	my $self = shift;
	my $id = shift;
	return $self->{_jobs}{$id};
}

#-------------------------------------------------------------------

=head3 getLogger ( )

Returns a reference to the logger.

=cut

sub getLogger {
	my $self = shift;
	return $self->{_logger};
}

#-------------------------------------------------------------------

=head2 loadSchedule ( config )

Loads the workflow schedule from a particular site.

=head3 config

The config filename for the site to load the schedule.

=cut

sub loadSchedule {
	my ($kernel, $self, $config) = @_[KERNEL, OBJECT, ARG0];
	$self->debug("Loading schedules for $config.");
	my $session = WebGUI::Session->open($self->config->getWebguiRoot, $config);
	my $result = $session->db->read("select * from WorkflowSchedule");
	while (my $data = $result->hashRef) {
		my $params = JSON::jsonToObj($data->{parameters});
		$data->{parameters} = $params->{parameters};
		$data->{config} = $config;
		$data->{gateway} = $session->config->get("gateway");
		$data->{sitename} = $session->config->get("sitename")->[0];
		$kernel->yield("addJob", $data);
	}
	$result->finish;
	$session->close;
}

#-------------------------------------------------------------------

=head2 new ( config, logger, workflow, [ debug ] )

Constructor.

=head3 config

A WebGUI::Config object that represents the spectre.conf file.

=head3 logger

A reference to the logger object.

=head3 workflow

A reference to the Worfklow session.

=head3 debug

A boolean indicating Spectre should spew forth debug as it runs.

=cut

sub new {
	my $class = shift;
	my $config  = shift;
	my $logger = shift;
	my $debug = shift;
	my $self = {_jobs=>{}, _debug=>$debug, _config=>$config, _logger=>$logger};
	bless $self, $class;
	my @publicEvents = qw(runJob runJobResponse addJob deleteJob);
	POE::Session->create(
		object_states => [ $self => [qw(_start _stop runJob runJobResponse addJob deleteJob checkSchedules checkSchedule loadSchedule), @publicEvents] ],
		args=>[\@publicEvents]
        	);
	my $cookies = HTTP::Cookies->new(file => '/tmp/cookies');
	POE::Component::Client::HTTP->spawn(
		Agent => 'Spectre',
		Alias => 'cron-ua',
		CookieJar => $cookies
  		);
}

#-------------------------------------------------------------------

=head2 runJob ( )

Calls a worker to execute a cron job.

=cut

sub runJob {
	my ($kernel, $self, $id, $session) = @_[KERNEL, OBJECT, ARG0, SESSION];
	$self->debug("Preparing to run a job ".$id.".");
	my $job = $self->getJob($id);
	if ($job->{sitename} eq "" || $job->{config} eq "" || $job->{taskId} eq "") {
		$self->error("A job has corrupt information and is not able to be run. Skipping execution.");
		$kernel->yield("deleteJob",$id);
	} elsif ($self->{_errorCount}{$id} >= 5) {
		$self->error("Job ".$id." has failed ".$self->{_errorCount}{$id}." times in a row and will no longer attempt to execute.");
		$kernel->yield("deleteJob",$id);
	} else {
		my $url = "http://".$job->{sitename}.':'.$self->config->get("webguiPort").$job->{gateway};
		my $request = POST $url, [op=>"runCronJob", taskId=>$job->{taskId}];
		my $cookie = $self->{_cookies}{$job->{sitename}};
		$request->header("Cookie",$job->{cookieName}."=".$cookie) if (defined $cookie);
		$request->header("User-Agent","Spectre");
		$request->header("X-jobId",$id);
		$self->debug("Posting job ".$id." to $url.");
		$kernel->post('cron-ua','request', 'runJobResponse', $request);
		$self->debug("Cron job ".$id." posted.");
	}
}

#-------------------------------------------------------------------

=head2 runJobResponse ( )

This method is called when the response from the runJob() method is received.

=cut

sub runJobResponse {
	my ($self, $kernel, $requestPacket, $responsePacket) = @_[OBJECT, KERNEL, ARG0, ARG1];
	$self->debug("Retrieving response from job.");
 	my $request  = $requestPacket->[0];
    	my $response = $responsePacket->[0];
	my $id = $request->header("X-jobId");	# got to figure out how to get this from the request, cuz the response may die
	$self->debug("Response retrieved is for job $id.");
	if ($response->is_success) {
		my $job = $self->getJob($id);
		if (defined $job && ref $job eq "HASH") {
			$self->debug("Response for job $id retrieved successfully.");
			if ($response->header("Set-Cookie") ne "") {
				$self->debug("Storing cookie for $id for later use.");
				my $cookie = $response->header("Set-Cookie");
				my $pattern = $job->{cookieName}."=([a-zA-Z0-9\_\-]{22}).*";
				$cookie =~ s/$pattern/$1/;
				$self->{_cookies}{$job->{sitename}} = $cookie;
			}
			my $state = $response->content; 
			if ($state eq "done") {
				delete $self->{_errorCount}{$id};
				$self->debug("Job $id is now complete.");
				if ($job->{runOnce}) {
					$kernel->yield("deleteJob",$id);
				}
			} elsif ($state eq "error") {
				$self->{_errorCount}{$id}++;
				$self->debug("Got an error response for job $id, will try again in ".$self->config->get("suspensionDelay")." seconds.");
				$kernel->delay_set("runJob",$self->config->get("suspensionDelay"),$id);
			} else {
				$self->{_errorCount}{$id}++;
				$self->error("Something bad happened on the return of job $id, will try again in ".$self->config->get("suspensionDelay")." seconds. ".$response->error_as_HTML);
				$kernel->delay_set("runJob",$self->config->get("suspensionDelay"),$id);
			}
		} else {
			$self->{_errorCount}{$id}++;
			$self->error("Job $id is not in our queue.");
		}
	} elsif ($response->is_redirect) {
		$self->error("Response for $id was redirected. This should never happen if configured properly!!!");
	} elsif ($response->is_error) {	
		$self->error("Response for job $id had a communications error. ".$response->error_as_HTML);
		$self->{_errorCount}{$id}++;
		$kernel->delay_set("runJob",$self->config->get("suspensionDelay"),$id);
	}
}


1;
