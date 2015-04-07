use strict;
use warnings;
use Test::More;
use Plack::Builder;

sub build_handler {
  my @args = @_;
  builder {
    enable "Plack::Middleware::XForwardedFor", @args;
    sub { my $env = shift; is($env->{REMOTE_ADDR}, $env->{__expect}) };
  };
}

my @tests = (
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __expect             => "10.55.1.2",
  },
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "1.2.3.4",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __trust              => ["127.0.0.1", "9.8/16"],
    __expect             => "10.55.1.2",
  },

  # The following tests check the functionality to override "header".
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __expect             => "1.2.3.4",
    __header             => 'HTTP_OTHER_HEADER',
  },
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_OTHER_HEADER    => "9.8.7.6",
    __expect             => "9.8.7.6",
    __header             => 'HTTP_OTHER_HEADER',
  },
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_OTHER_HEADER    => "5.6.7.8",
    HTTP_X_FORWARDED_FOR => "9.10.11.12",
    __expect             => "5.6.7.8",
    __header             => 'HTTP_OTHER_HEADER',
  },

  # Also checking the code that fixes the header name.
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_OTHER_HEADER    => "9.8.7.6",
    __expect             => "9.8.7.6",
    __header             => 'Other-Header',
  },
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __expect             => "9.8.7.6",
    __header             => 'X-Forwarded-For',
  },
);

foreach my $env (@tests) {
  build_handler(trust => $env->{__trust}, header => $env->{__header})->($env);
}

done_testing();
