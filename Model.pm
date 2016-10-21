#https://metacpan.org/release/DBIx-OO
package Model;

use strict; use warnings;

use Core::DB;


sub db_tcolumns() { qw// }

sub new() {
	my ($class,$arg) = @_;

	my $self = {};

	if ($arg->{id}){
		$self = load( $class, $arg->{id});
	} else{
		bless $self,$class;
	}

	$self->set($arg);
	return $self;
}



sub newid(){
	my $self = shift; return $db->lastInsertId() || $self->{id};
}

sub filter(){ return undef;}
sub union_filter(){ return undef; }
sub _check_write_permissions(){ return undef; }
sub _check_columns_values(){ return undef; }
sub _before_save(){ return 1; }

sub list(){
	my ($class,$arg) = @_;
	my $q = 'SELECT id FROM '.$class->db_table().' ';
	$q .= ' ORDER BY name' if grep /^name$/, $class->db_columns();
	my $sth = $db->prepare($q);
	$sth->execute();
	my @buf;
	eval "use $class;";

	while (my ($id) = $sth->fetchrow_array){
		push @buf, $class->load($id);
	}

	return \@buf;
}

sub list_where(){
    my ( $class, $value , $column ) = @_;

    my $q = "SELECT id FROM ".$class->db_table()." WHERE ".($column || 'id')." = ?";
    $q .= ' ORDER BY name' if grep /^name$/, $class->db_columns();

    my $h = $db->prepare( $q );
    $h->execute( $value || 0);
    eval "use $class;"; my @b = ();

    while ( my ( $id ) = $h->fetchrow_array ) {
  	  push @b, $class->load( $id );
  	}

  	return \@b;
}

sub _get_alias() {
	my $self  = shift;


	return 0 unless grep /^name$/,  $self->db_columns();
	return 0 unless grep /^alias$/, $self->db_columns();

	return 0 unless $self->{name};



	$self->{alias}
		||=  lc( Base::Translate->translate( $self->{name} ) ) ;

##	$log->debug('_get_alias(): '.$self->{name}.' '.$self->{alias});
##	return $self->{alias};

}

sub save(){
	my $self = shift;

	unless ($self->_before_save()){
		return undef;
	}

	$self->_get_alias();
	$self->_store_in_db();

	return $self;
}

sub _store_in_db(){
	my $self = shift;

	my $q = $self->{id} ? 'UPDATE' : 'INSERT';

	$q .= ' '.$self->db_table.' SET';

	my @binds;

	my @keys;

	foreach my $key ($self->db_columns){
	next unless defined $self->{$key};
	next if $key eq 'id';
	if ($self->{"${key}NULL"}){
		push @keys, "$key = ?";
		push @binds,undef;
	}elsif($self->{$key} =~ /^[A-Z_]+\(.*\)$/){
		push @keys,"$key = $self->{$key}"; #function (e.q. NOW())
	}elsif($self->{$key} ne ''){
		push @keys,"$key = ?";
		push @binds,$self->{$key};
	}
	}
	$q .= ' '.join (',',@keys);

	if ($self->{id}){
	$q .= ' WHERE id = ?';
	push @binds,$self->{id};
	}

#    warn "SQL: $q\nBinds: ".join(',',@binds)."\n";

	my $sth = $db->prepare($q);

	$sth->execute(@binds) or do { $self->_err_save_failed($sth); return undef; };

	$self->{id} ||= $self->newid();

	return 1;
}


sub load(){
	my ($class,$value,$column) = @_;

	$column ||= 'id';

	return undef
		unless $value;

	my $self = ();

	$self = &_fetch_from_db($class,$column,$value)
		or return &Model::Error('unable to load model');

	return $self;
}

sub set(){
	my ($self,$args) = @_;
	foreach my $col ($self->db_columns){
	$self->{$col} = $args->{$col} if defined $args->{$col};
	}
	foreach my $key(keys %$args){
	$self->{$key} = 1 if $key =~ /.*NULL$/;
	}
	return 1;
}

sub reload(){
	my $self = shift;
	$self->_refetch_from_db;
	return 1;
}

sub delete(){
	my $self = shift;
#	return undef unless $self->_check_write_permissions();
#	$self->_before_delete();
	#$self->{deleted} = 1;
#	my $q = 'delete from '.$self->db_table().' WHERE id = '.$self->{id};
#	my $sth = $db->prepare($q);
#	$sth->execute();

	$self->_delete_from_db();
}

sub _before_delete(){ return undef; }

sub einput(){
	my ($self,$msg) = @_;
	unless ($self->{_errs}){
	$self->{_errs} = ModelErrors->new();
	}
	$self->{_errs}->put('input',$msg);
}
sub errs(){
	my $self = shift;
	unless ($self->{_errs}){
	$self->{_errs} = ModelErrors->new();
	}
	return $self->{_errs}->get('input');
}

sub _refetch_from_db(){
	my $self = shift;

	my $sth = $db->prepare('SELECT * FROM '.$self->db_table." WHERE id = ? where delete != 1");
	$sth->execute($self->{id}) or return &Model::Error("Error in SQL: ".$sth->errstr);
	my $data = $sth->fetchrow_hashref;
	foreach my $key (%$data){
	$self->{$key} = $data->{$key};
	}
	$self;
}

sub _fetch_from_db(){
    my ( $c, $cl, $v ) = @_;
    my $h = $db->prepare( 'SELECT '. join( ',', $c->db_columns() ).' FROM '.$c->db_table().' WHERE '.$cl.' = ?' );
    $h->execute( $v )			or return &Model::Error("Err:".$h->errstr );
    my $o = $h->fetchrow_hashref() 	or return &Model::Error("Err:".$h->errstr );
    return bless $o, $c;
}


sub _delete_from_db(){
	my $self = shift;

	my $sth = $db->prepare('delete from '.$self->db_table.' WHERE id = ?');

	$sth->execute($self->{id})
	  or return $self->Error('err delete '.$self->db_table.' with id = '.$self->{id});
}

sub Error(){
	my ($self,$e) = @_;
	$e = $self unless $e;
#    warn "[Model]: $e";
	return undef;
}

package Core::PriceTool;
use Core::DB;
sub new(){
	my ($class,$value) = @_;
	my $self = { price => $value };
	return bless $self,$class;
}
sub price(){
	my ($self,$code) = @_;
   return $self->{price} unless $code;
   unless ($self->{_price}->{$code}){
		my $sth = $db->prepare('SELECT value FROM currency WHERE code = ?');
	$sth->execute($code);
	my ($value) = $sth->fetchrow_array || (1);
	$self->{_price}->{$code} = sprintf('%.2f',$self->{price} * $value);
   }
   return $self->{_price}->{$code};
}

package ModelList;
use Core::DB;
sub new(){
	my $class = shift;
	my $self = {
	modelclass => shift ,
	rows => 0,
	page => shift || 0,
	pp => shift || 10,
	skip_external_filter => 0,
	filter => {},
	like => {},
	order => [],
	fulltext => {},
	funcs => [],
	innerjoin => [],
	filter_not => {},
	filter_is_null =>{},
	filter_or => [],
	func_columns => {},
	groupby => [],
	extsql => '',
	};
	return undef unless $self->{modelclass};
	return bless $self,$class;
}

sub extsql(){
	my $self = shift;
	my $s = shift;
	$self->{extsql} .= ' AND ('.$s.')';
}

sub func_column(){
	my $self = shift;
	my %args = @_;
	foreach my $key (keys %args){
	$self->{func_columns}->{$key} = $args{$key};
	}

}

sub skip_external_filter(){
	my $self = shift;
	$self->{skip_external_filter} = shift;
}

sub innerjoin(){
	my $self = shift;
	my %args = @_;


	foreach my $key (keys %args){
	my $f=0;
	foreach my $join (@{$self->{innerjoin}}){
		$f=1 if $key eq $join->{key};
	}
	next if $f;
	push @{$self->{innerjoin}}, {
		key => $key,
		djoin => $args{$key},
	};
	}

}

sub fulltext(){
	my $self = shift;
	my %args = @_;
	foreach my $key (keys %args){
	$self->{fulltext}->{$key} = $args{$key} if $args{$key};
	}

}

sub func(){
	my $self = shift; foreach my $func (@_){ push @{$self->{funcs}}, $func; }
}

sub filter(){
	my $self = shift;
	my %args = @_;
	foreach my $key (keys %args){
	my $val;
	if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
		$val = $1.'.'.$2;
	}else{
		$val = $self->{modelclass}->db_table() .'.'.$key;
	}
	$self->{filter}->{$val} = $args{$key} if defined $args{$key};
	}

#    $self->load();
}

sub filter_or(){
	my $self = shift;

	my %args = @_;

	my $h = {};
	foreach my $key (keys %args){
	my $val;
	if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
		$val = $1.'.'.$2;
	}else{
		$val = $self->{modelclass}->db_table() .'.'.$key;
	}

	warn "Adding $val = $args{$key} to filter_or";
	$h->{$val} = $args{$key} if $args{$key};
	}

	push @{$self->{filter_or}}, $h;

}

sub filter_not(){
	my $self = shift;
	my %args = @_;

	foreach my $key (keys %args){
		my $val;
		if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
			$val = $1.'.'.$2;
		}else{
			$val = $self->{modelclass}->db_table() .'.'.$key;
		}
		$self->{filter_not}->{$val} = $args{$key} if defined $args{$key};
	}
#    $self->load();
}

sub filter_is_null(){
	my $self = shift;
	my %args = @_;
	foreach my $key (keys %args){
		my $val;
		if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
			$val = $1.'.'.$2;
		}else{
			$val = $self->{modelclass}->db_table() .'.'.$key;
		}
		$self->{filter_is_null}->{$val} = $args{$key} if defined $args{$key};
	}
#    $self->load();
}
sub like(){
	my $self = shift;
	my %args = @_;
	foreach my $key (keys %args){
	my $val;
	if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
		$val = $1.'.'.$2;
	}else{
		$val = $self->{modelclass}->db_table() .'.'.$key;
	}
	$self->{like}->{$val} = $args{$key} if $args{$key};
	}
}

sub groupby(){
	my $self = shift;
	foreach my $group (@_){
	push @{$self->{groupby}}, $group;
	}
}

sub order(){
	my $self = shift;
	foreach my $key (@_){
	my $val;
	if ($key =~ /^([a-zA-Z0-9]+)\.([A-Za-z0-9]+)/ ){
		$val = $1.'.'.$2;
	}else{
		if (grep (/^$key$/, keys( %{$self->{func_columns}}))){
			$val = $key;
		}else{
			$val = $self->{modelclass}->db_table() .'.'.$key;
		}
	}
	push @{$self->{order}}, $val if $key;
	}
}

sub order_desc()	{ my $self = shift; $self->{order_desc} = 1; }
sub only_price()	{ my $self = shift; $self->{only_price} = 1; }
sub clearfitler()	{ my $self = shift; $self->{filter} = {}; 	}
sub list()			{ my $self = shift; $self->load unless $self->{list}; return $self->{list}; }


sub load(){
	my $self = shift;

	$self->{list} = [];
	my $ather_tables;

	unless ($self->{skip_extenranl_filter}){ $self->{modelclass}->filter($self); }

	my $mytable = $self->{modelclass}->db_table;

	my $q = "SELECT SQL_CALC_FOUND_ROWS ";
	$q .= " DISTINCT";
	$q .= " $mytable.id ".$ather_tables;
	foreach my $func_col(keys %{$self->{func_columns}}){ $q .= ', '.$self->{func_columns}->{$func_col}.' AS '.$func_col; }
	$q .= " FROM $mytable ";
	foreach my $jointbl (@{$self->{innerjoin}}){ $q .= ' INNER JOIN '.$jointbl->{key} .' ON '. $jointbl->{djoin}->{from} .' = '. $jointbl->{djoin}->{to}; }
	$q .= ' WHERE 1 ';
	my @values;
	foreach my $key (keys %{$self->{filter}}){
		if (ref($self->{filter}->{$key}) eq 'ARRAY'){
			my @buf = map {$_ = "'$_'"} @{$self->{filter}->{$key}};
			$q .= " AND $key IN (".join (',',@buf).')';
		} else {
				$q .= " AND $key = ? ";
				warn "have filter $key";
		}
		push @values,$self->{filter}->{$key};

	}

	foreach my $key (keys %{$self->{filter_is_null}}){
	$q .= " AND $key is null";
	warn "have filter $key is not null";
	}
	my $qo=undef;

	foreach my $item (@{$self->{filter_or}}){
	$q .= ' AND ( 0 ';
	foreach my $key (keys %$item){
		if (ref($item->{$key}) eq 'ARRAY'){
		my @buf = map {$_ = "'$_'" unless $_ =~ /^'.+'$/} @{$item->{$key}};
		$q .= " OR $key IN (".join (',',@buf).') ';
		}else{
		$q .= " OR $key = ? ";
		push @values,$item->{$key};
		}
	}
	$q .= ') ';
	}

	foreach my $key (keys %{$self->{fulltext}}){
	$q.= ' AND MATCH('.join (',',@{$self->{fulltext}->{$key}}).') AGAINST (?)';
	push @values,$key;
	}

	foreach my $func( @{$self->{funcs}}){
	$q .= " AND $func ";
	}

	foreach my $key (keys %{$self->{like}}){
	$q .= " AND $key LIKE ? ";
	push @values,$self->{like}->{$key};
	}

	 if (my $sql = $self->{extsql}){
	 $q .= $sql;
	 }

	if (@{$self->{groupby}}){
	$q .= ' GROUP BY '.join(',',@{$self->{groupby}});
	}


	if(@{$self->{order}}){
	$q .= ' ORDER BY '.join(',',@{$self->{order}});
	$q .= ' DESC ' if $self->{order_desc};
	}


	$q .= ' LIMIT ' . $self->{page}*$self->{pp} . ',' . $self->{pp};

	warn "ModlesList request:\n$q\n";

	my $sth = $db->prepare($q);
	$sth->execute(@values) 
	    or return $self->Error('can`t load '.$self->{modelclass}.': '.$sth->errstr);
	$self->_set_found_rows();

	while (my ($id) = $sth->fetchrow_array){
	    push @{ $self->{list} }, $self->{modelclass}->load($id);
	}
}

sub _set_found_rows(){
	my $self = shift;
	my $sth = $db->prepare('SELECT FOUND_ROWS()');
	$sth->execute();
	($self->{rows}) = $sth->fetchrow_array;
}

sub pagesa(){
	my $self = shift;
	my @buf;
	for(my $i=1;$i<=$self->pages;$i++){
	push @buf,$i;
	}
	return \@buf;
}

sub pages(){
	my $self = shift;
	return 0 if $self->{rows} == 0;
	my $div = sprintf('%u',$self->{rows}/$self->{pp});
	return $self->{rows} % $self->{pp} ? ++$div : $div;
}



sub Error(){
	my $self = shift;
	my $e = shift;
	my $caller = caller;
	warn "[ModelList] $e";

	return undef;
}


package ModelErrors;
sub new(){
	my $class = shift;
	my $self = {
		input => undef,
		sys => undef,
		db => undef,
	};
	bless $self,$class;
}

sub put(){
	my ($self,$type,$msg) = @_;
	warn "[ModelError][$type]: $msg\n";
	push @{$self->{$type}},$msg;
	return undef;
}

sub get(){
	my ($self,$type) = @_;
	return $self->{$type};
}
1;
