package Log::Log4perl::Shortcuts ;

use 5.10.0;
use Carp;
use Log::Log4perl;
use Log::Log4perl::Level;
use Path::Tiny;
use Module::Data;
use File::UserConfig;
use Data::Dumper qw(Dumper);

require Exporter;
@ISA = Exporter;
@EXPORT_OK = qw(logc logt logd logi logw loge logf set_log_config set_log_level get_log_config);
%EXPORT_TAGS = ( all => [qw(logc logt logd logi logw loge logf set_log_config set_log_level get_log_config)] );
Exporter::export_ok_tags('all');

my $package = __PACKAGE__;
$package =~ s/::/-/g;
my $config_file;
my $config_dir = path(File::UserConfig->new(dist => $package)->sharedir, 'log_config');

my $default_config_file = path($config_dir, 'default.cfg');

if (!$default_config_file->exists) {
  carp ("Unable to load default Log::Log4perl::Shortcuts configuration file. Aborting");
} else {
  Log::Log4perl->init_once($default_config_file->canonpath);
  $config_file = $default_config_file->canonpath;
}

my $log_level = $TRACE;

### Public methods ###

sub get_log_config {

}

sub set_log_config {
  my $new_config = shift;
  my $module = shift || '';

  # must pass in name of a file
  if (!$new_config) {
    logw('No log config file passed. Configuration file unchanged');
    return;
  }

  # try to get config file from path passed directly in
  my $cf_path = path($new_config);
  if ($cf_path->exists) {
    return _init_config($cf_path);
  }

  # try to get the config from the module argument or pkg of caller
  if (!$module) {
    ($module) = caller;
  }
  $module =~ s/::/-/g;
  my $temp_config_dir;
  eval {
    my $share_dir = File::UserConfig->new(dist => $module)->sharedir;
    if ($share_dir) {
      $temp_config_dir = path(File::UserConfig->new(dist => $module)->sharedir, 'log_config');
    }
  };
  if ($temp_config_dir) {
    $cf_path = path($temp_config_dir, $new_config);
    if ($cf_path->exists) {
      return _init_config($cf_path);
    }
  }

  # Lastly, check the Log::Log4perl::Shortcuts module for config file
  $temp_config_dir = $config_dir;
  $cf_path = path($temp_config_dir, $new_config);

  if (! $cf_path->exists) {
    carp ("Configuration file $new_config does not exist. Configuration file unchanged.");
  } else {
    return _init_config($cf_path);
  }
}

sub _init_config {
  my $config = shift;
  Log::Log4perl->init($config->canonpath);
  $config_file = $config->canonpath;
  return 'success';
}

sub set_log_level {
  my $level = ${uc(shift)};
  $log_level = $level;
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

  $log->logwarn($msg);
}

sub loge {
  my $msg = shift;

  my $log = '';
  my $options = {};
  my $next_arg = shift;
  if (ref $next_arg) {
    my $options = shift;
  } else {
    $log = _get_logger($next_arg);;
  }

  return unless $log->is_error;

  $msg = sprintf("%-80s %s\n", $msg, [caller(0)]->[0] . ": line " . [caller(0)]->[2]);
  if ($options->{show_callers}) {
    $msg .= '        ' . _get_callers();
    chomp $msg;
    chomp $msg;
  }
  $log->error_warn($msg);
}

sub logf {
  my $msg = shift;

  my $log = '';
  my $options = {};
  my $next_arg = shift;
  if (ref $next_arg) {
    my $options = shift;
  } else {
    $log = _get_logger($next_arg);;
  }

  return unless $log->is_fatal;

  $msg = sprintf("%-80s %s\n", $msg, [caller(0)]->[0] . ": line " . [caller(0)]->[2]);
  if ($options->{show_callers}) {
    $msg .= '        ' . _get_callers();
    chomp $msg;
    chomp $msg;
  }

  $log->logdie($msg);
}
### Private methods ###
sub _get_logger {
  my $category = shift || '';
  my $logger = Log::Log4perl->get_logger((caller(1))[0] . ($category ? '.' . $category : '') );
  $logger->level($log_level);
  return $logger;
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

Provides an easy-to-use wrapper for L<Log::Log4perl>.

=head1 SYNOPSIS

Instead of this:

  use Log::Log4perl;

  sub do_something {
    my $logger = Log::Log4perl->get_logger('my.category');

    $log->info('I am doing something.');
  }

You can save some keystrokes and do this:

  use Log::Log4perl::Shortcuts qw(:all);

  sub do_something {
    logi('I am doing something.', 'my.category');
  }

=head1 DESCRIPTION

This modules provides shortcut functions for the standard log levels provided by
L<Log::Log4perl> plus some additional functionality to make it more convenient.

All functions can be imported into your module or script with the C<:all> import
tag or they can be individually imported.

=head2 Log level functions

There are the six log level functions provided, one for each of the standard log
levels provided by the Log4perl module. Each of them accepts an argument for the
log message plus an optional category argument.

The B<$category> arguments, if supplied, are appended to the name of the calling
package where the log command was invoked. For example, if C<logi('Info log entry', 'my_category')>
is called from package C<Foo::Bar>, the log entry will be made with the category:

The B<$options> arguments, if avaiable, supply addition options to the C<loge>
and C<logf> functions. If C< { show_callers =E<gt> 1 } > is supplied, a stack trace
will be printed out below the error or fatal message.

  Foo::Bar.my_category

=func logt ($msg, [$category])

Prints a message to the I<trace> logger when the log level is set to B<TRACE> or above.

=func logd ($msg, [$category])

Print messages when the log level is set to B<DEBUG> or above. B<$category>
argument is optional.

B<$msg> is intended to be a scalar variable or reference to a data structure which
will be output as a message after getting passed through L<Data::Dumper>.

=func logi ($msg, [$category])

Prints a message to the I<info> logger when the log level is set to B<INFO> or above.

=func logw ($msg, [$category])

Prints a message to the I<warn> logger when the log level is set to B<WARN> or above.

=func loge ($msg, [$category], [{ $options => value, ... }])

Prints a message to the I<error> logger when the log level is set to B<ERROR> or above.

=func logf ($msg, [$category], [{ $options => value, ... }])

Prints a message to the I<fatal> logger when the log level is set to B<FATAL> or above.

=head2 Special functions

=spec_func logc ([$category])

Prints call stack when log level is set to B<TRACE> or above. Note that no
message argument is used by this function.

=spec_func set_log_config ($file, ['MODULE::NAME'])

Changes the log configuration file to the path and/or
file name specified with C<$file>.

C<Log::Log4perl::Shortcuts> will first try to locate the config file on your
hard drive using the C<$file> argument by itself. If that's not
successful, it will attempt to locate the file in the C<log_config> directory
within your module's shared directory. If that fails, the C<log_config> directory
for C<Log::Log4perl::Shortcuts> will be searched. This directory can be
found in C<Log-Log4perl-Shortcuts> directory that L<File::UserConfig>
installed in your home directory when you installed C<Log::Log4perl::Shortcuts>.

You can also supply the name of another module installed on your system which
has its logs located in a C<log_config> directory within that module's shared
directory.

=spec_func set_log_level ($log_level)

Change the log level. Should be one of 'trace', 'debug', 'info', 'warn', 'error',
or 'fatal'.

=head1 CONFIGURATION AND ENVIRONMENT

Custom log configuration files work seamlessly when C<Log::Log4perl::Shortcuts>
is being called from within a module that uses the L<File::UserConfig> module
to create a directory in your home directory for placing configuration files.
If this is the case, place your custom log files into your module's C<log_config>
directory so your custom log files can be found. On a Mac, by default, this
directory is found in the C<Application Support/Your-Module-Name> in your
user's home directory.

You may still use C<Log::Log4perl::Shortcuts> with a custom log file without
using the C<File::UserConfig> module, but you will need to specify the complete
path to the custom log file when calling the C<set_log_config> function or place
your custom log configuration files in the C<Log-Log4perl-Shortcuts/log_config>
directory found in your home directory.

=head1 DEPENDENCIES

=head1 AUTHOR NOTES

=head2 Development status

This module is currently in the beta stages and is actively supported and maintained.
Suggestion for improvement are welcome.

=head2 Motivation

Provide motivation for writing the module here.

#=head1 SEE ALSO
