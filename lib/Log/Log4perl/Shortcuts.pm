package Log::Log4perl::Shortcuts ;

use Carp;
use Log::Log4perl;
use File::HomeDir;
use Data::Dumper qw(Dumper);

require Exporter;
@ISA = Exporter;
@EXPORT_OK = qw(logc logt logd logi logw loge logf change_config_file);
%EXPORT_TAGS = ( all => [qw(logc logt logd logi logw loge logf change_config_file)] );
Exporter::export_ok_tags('all');

BEGIN { 
  our $config_dir = '/perl/log_config/';
  our $current_config = 'default2.cfg';
  our $home_dir = File::HomeDir->my_home;
  my $file = $home_dir . $config_dir . $current_config;
  if (!-f $file) { 
    Log::Log4perl->init_once('config/default.cfg');
  } else {
    Log::Log4perl->init_once($file);
  }
};


### Public methods ###

sub change_config_file {
  $current_config = shift;
  my $file = File::HomeDir->my_home . $config_dir . $current_config;
  if (!-f $file) { 
    carp ("Configuration file $file does not exist. Configuration file unchanged.");
  } else {
    Log::Log4perl->init($file);
    return 'success';
  }
}

sub logc {
  my $log = _get_logger(shift);
  return unless $log->is_trace;

  my $msg = sprintf(' ' x 81 . "%s\n", [caller(0)]->[0] . ": " . [caller(0)]->[2]);
  $msg .= '        ' . _get_callers() . "\n       ";

  $log->trace($msg);
}

sub logt {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_trace;

  $log->trace($msg);
}

sub logd {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_debug;

  $msg = Dumper ($msg);
  $log->debug($msg);
}

sub logi {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_info;

  $log->info($msg);
}

sub logw {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_warn;

  $log->warn($msg);
}

sub loge {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_error;

  $msg = sprintf("%-80s %s\n", $msg, [caller(0)]->[0] . ": " . [caller(0)]->[2]);
  $msg .= '        ' . _get_callers();
  chomp $msg;
  chomp $msg;

  $log->error($msg);
}

sub logf {
  my $msg = shift;

  my $log = _get_logger(shift);;
  return unless $log->is_fatal;

  $log->fatal($msg);
  die "\n";
}

### Private methods ###
sub _get_logger {
  my $category = shift || '';
  return Log::Log4perl->get_logger((caller(1))[0] . ($category ? '.' . $category : '') );
}

sub _get_callers {
  my @callers = ();
  my $has_sub = 1;
  foreach (my $depth = 2; $has_sub; $depth++) {
    my $caller = [caller($depth)]->[3] . ': ';
    $has_sub = [caller($depth + 1)]->[3];
    $caller .= $has_sub ? [caller($depth)]->[2] : 'main ' . [caller($depth)]->[2];
    push @callers, $caller;
  }
  my $msg = join "\n        ", @callers;
  return $msg;

}

1; # Magic true value
# ABSTRACT: shortcut functions to make log4perl even easier

__END__

=head1 OVERVIEW

Provides shortcut functions to frequently used Log4perl methods.

=head1 SYNOPSIS

Instead of this:

  use Log::Log4perl;

  sub do_something {
    my $logger = Log::Log4perl->get_logger('my.category');

    $log->info('I am doing something.');
  }

Save some keystrokes and do this:

  use Log::Log4perl;
  use Log::Log4perl::Shortcuts qw(:all);

  sub do_something {
    logw('I am doing something.', 'my.category');
  }

=head1 DESCRIPTION

This modules provides shortcut functions for each log level corresponding
to the level you wish the log message to be seen plus additional special shortcut
functions.
  

=head2 Log level functions

Below are the six log level functions, one for each of the standard log levels provided
by the Log4perl module. Each of them accepts an argument for the log message
plus an optional category argument. 

The B<$category> arguments, if supplied, are appended to the name of the calling
package where the log command was invoked. For example, if C<logi('Info log entry', 'my_category')>
is called from package C<Foo::Bar>, the log entry will be made with the category:

  Foo::Bar.my_category

=func logt($msg, [$category])

Prints a message to the I<trace> logger when the log level is set to B<TRACE> or above. 

=func logd($msg, [$category])

Print messages when the log level is set to B<DEBUG> or above. B<$category>
argument is optional.

B<$msg> is intended to be a scalar variable or reference to a data structure which
will be output as a message after getting passed through L<Data::Dumper>.

=func logi($msg, [$category])

Prints a message to the I<info> logger when the log level is set to B<INFO> or above. 

=func logw($msg, [$category])

Prints a message to the I<warn> logger when the log level is set to B<WARN> or above. 

=func loge($msg, [$category])

Prints a message to the I<error> logger when the log level is set to B<ERROR> or above. 

=func logf($msg, [$category])

Prints a message to the I<fatal> logger when the log level is set to B<FATAL> or above. 

=head2 Special function

=func logc([$category])

Prints call stack when log level is set to B<TRACE> or above. Note that no
message argument is used by this function.


#=head1 CONFIGURATION AND ENVIRONMENT
#
#{{$name}} requires no configuration files or environment variables.


=head1 DEPENDENCIES

=head1 AUTHOR NOTES

=head2 Development status

This module is currently in the beta stages and is actively supported and maintained. Suggestion for improvement are welcome.

- Note possible future roadmap items.

=head2 Motivation

Provide motivation for writing the module here.

#=head1 SEE ALSO
