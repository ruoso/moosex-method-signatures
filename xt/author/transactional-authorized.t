use Test::More;
use Test::Moose;

{ package MyClass;
  use Moose;
  use MooseX::Method::Signatures;
  use aliased 'MooseX::Meta::Method::Transactional';
  use aliased 'MooseX::Meta::Method::Authorized';

  has user => (is => 'ro');
  has schema => (is => 'ro');

  # this was supposed to die, but the trait is not really applied.
  method m01($p1, $p2) does Transactional does Authorized(requires => ['foo']) { 'm01'.$p1.$p2 }
  method m02($p1, $p2) does Transactional { 'm02'.$p1.$p2 }
  method m03($p1, $p2) does Authorized(requires => ['gah']) { 'm03'.$p1.$p2 }
  method m04($p1, $p2) does Transactional does Authorized(requires => ['gah']) { 'm01'.$p1.$p2 }

};
{ package MySchema;
  use Moose;
  sub txn_do {
      my $self = shift;
      my $code = shift;
      return 'txn_do '.$code->(@_);
  }
};
{ package MyUser;
  use Moose;
  sub roles { qw<foo bar baz> }
};

my $meth = MyClass->meta->get_method('m01');
my $obj = MyClass->new({user => MyUser->new, schema => MySchema->new });

is($obj->m01(1,2), 'txn_do m0112', 'applying both roles work.');
is($obj->m02(3,4), 'txn_do m0234', 'Applyign just Transactional');
eval {
    $obj->m03(5,6);
};
like($@.'', qr(Access Denied)i, $@);

eval {
    $obj->m04(7,8);
};
like($@.'', qr(Access Denied)i, $@);

done_testing();
1;
