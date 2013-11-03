package Died;

use English;
use Scalar::Util qw(blessed);

use overload q("") => "stringify";

our $VERSION = 0.02;

sub import {
    my $class = shift;

    my $where = shift // caller;

    my $fn = "die";
    my $pkg = __PACKAGE__;
    no strict qw(refs);
    *{"${where}::$fn"} = \&{"${pkg}::$fn"};
}

sub die (@) {
    if (blessed($ARG[0])) {
        CORE::die(@ARG);
    }

    if (0 == @ARG) {
        my (undef, $file, $line, undef) = caller(0);
        $EVAL_ERROR->PROPAGATE($file, $line) if blessed($EVAL_ERROR) && $EVAL_ERROR->can("PROPAGATE");
        CORE::die;
    }

    my %hack = ();

    my $class = __PACKAGE__;
    
    $EVAL_ERROR = bless(\%hack, $class);
    $EVAL_ERROR->_init(@ARG);

    CORE::die($EVAL_ERROR);
}

sub _init {
    my $this = shift;

    my ($package, $file, $line, $sub) = caller(1);

    $$this{package} = "main" eq $package ? $PROGRAM_NAME : $package;
    $$this{file} = $file;
    $$this{line} = $line;
    $$this{caller} = $sub;
    $$this{arg} = 0 == @ARG ? ["Died"] : [$ARG[0]];
}

sub file {
    return($ARG[0]{file});
}

sub line {
    return($ARG[0]{line});
}

sub stringify {
    my ($this) = @ARG;

    my $arg = $$this{arg}[0];

    my $at_line = sprintf(" at %s line %s\n", $$this{package}, $$this{line});

    if ($arg !~ m/\Z\n/) {
        $arg .= $at_line;
    }

    return($arg);
}

sub PROPAGATE {
    my ($this, $FILE, $LINE) = @_;

    my $str = $this->stringify;
    $$this{arg} = ["$str\t...propagated at $FILE line $LINE.\n"];

    return($this);
}

1;

__END__

=head1 NAME

Died - Auto create blessed exceptions

=head1 SYNOPSIS

    package OldCode;

    use Died;

    sub inuse {
        eval {
            maintenace();
        };
        if ($@) {
            die;
        }
    }

    sub maintenace {
        die("Use the source!\n");
    }

    package main;

    use Died;
    use English;
    use Modern::Perl;

    eval {
        OldCode::inuse;
    };
    if ($EVAL_ERROR) {
        say($EVAL_ERROR->file, "\t", $EVAL_ERROR->line);
    }


=head1 DESCRIPTION

L<Died> will auto create exception handling objects.  

The goal is to make it easer to use with maintenance code.

=cut
