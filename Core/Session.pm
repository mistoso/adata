package Core::Session;

use Error;
use Logger;
use Base::Exception;
use Data::Dumper;
use DB;
use Apache2::Cookie;
use Apache2::RequestUtil;

use Digest::MD5;
use MIME::Base64;
use Storable qw(nfreeze thaw);

our $_instance ;

use constant COOKIE_NAME => q/SessionKey/;
use constant KEY_LENGTH  => 32;
use constant EXPIRE      => 600;

#--------------------------------------------------------------------------------------------------
# I had a lot of problems when used Class::Singleton,
# Lost sessions due to the fact that the object is not created 
# ( Singleton apparently believed that he had already created ).
# I don't understood why is actually was... 
# 'force' option allows you to avoid that problems 
#--------------------------------------------------------------------------------------------------
sub instance {
	my $class = shift;
	my $force = shift;
	
	return $$_instance->{class} = $class->_new_instance(@_) if $force;
	
	defined $$_instance->{class} ?	$$_instance->{class} : 	($$_instance->{class} = $class->_new_instance(@_));
}
#--------------------------------------------------------------------------------------------------

sub _new_instance {
	my $class = shift;

	my $this  = ();
	$this  = bless { }, $class;
	if (my $r = Apache2::RequestUtil->request()) {

		#get cookie
		#(undef,$this->{_session_id}) = map { split /=/, $_, 2 } split /; /, $ENV{'HTTP_COOKIE'}; 

                my @cookie =  split /; /, $ENV{'HTTP_COOKIE'};
                foreach (@cookie) {
                        my ($key,$value) = split /=/;
                        $this->{_session_id} = $value if $key eq COOKIE_NAME;
                }

		if ($this->{_session_id}) {
			$log->info(__PACKAGE__.':Session key in cookie is '.$this->{_session_id});
			$this->_materialize();
			if ($this->{serialized}) {
				$this->_unserialize();
				delete $this->{serialized};
				#$this->_checkObsolete();
			}
			else {
				# Just generate new one
				$this->_generateSessionId();
				$this->{insert} = 1;
				$this->{modify} = 1;
			}

		}
		else {
			$this->_generateSessionId();
			$this->{insert} = 1;	
			$this->{modify} = 1;
		}

		#my $cookie = Apache2::Cookie->new($r,-name => COOKIE_NAME, -value => $this->{_session_id},-path  => '/');
		#$cookie->bake($r);

		$r->headers_out->add('Set-Cookie' => COOKIE_NAME.'='.$this->{_session_id}.'; PATH=/;');
		$this->{data}->{_session_atime} = time();
	}
	
	$log->info(__PACKAGE__.':Session key is '.$this->{_session_id});

	return $this;
}

#--------------------------------------------------------------------------------------------------
sub deleteObj {
	$this = shift;
}
#--------------------------------------------------------------------------------------------------
sub dumper {
	my $this = shift;
		
	return $this->{_session_id}." ".Dumper($this->{data});
}

#--------------------------------------------------------------------------------------------------
sub set {
	my $this  = shift;
	my $key   = shift;
    my $value = shift;

    $this->{modify} = 1;

    if ($value) {
        $this->{data}->{$key} = $value;
    }
    else {
        if ( ref( $this->{data}->{$key} ) eq 'HASH') {
            $this->{data}->{$key} = {};
        }
        elsif ( ref( $this->{data}->{$key} ) eq 'ARRAY' ) {
            $this->{data}->{$key} = [];
        }
        else {
            $this->{data}->{$key} = '';
        }
    }
}
#--------------------------------------------------------------------------------------------------
sub get {
	my $this = shift;
	my $key  = shift;

	return $this->{data}->{$key};
}

sub remove {
	my $this = shift;
	my $key  = shift;
	
	$this->{modify} = 1;

	delete $this->{data}->{$key};
}
#--------------------------------------------------------------------------------------------------
sub save {
	my $this = shift;
	
	if ($this->{modify}) {
		delete $this->{modify};

		$this->_serialize();

		if ($this->{insert}) {
			$this->_insert();
			delete $this->{insert};
		}
		else {
			$this->_update();
		}

		delete $this->{serialized};
	}	
}
#--------------------------------------------------------------------------------------------------
sub _insert {
	my $this = shift;

	$this->_insertMySQL();
}
#--------------------------------------------------------------------------------------------------
sub _rename {
	my $this = shift;

	$this->{_old_session_id} = $this->{_session_id};
	$this->_generateSessionId();
	$this->_renameMySQL();
	$log->info(__PACKAGE__.': Rename '.$this->{_old_session_id}.' into '.$this->{_session_id});

	delete $this->{_old_session_id};
}
#--------------------------------------------------------------------------------------------------
sub _update {
	my $this = shift;

	$this->_updateMySQL();

}
#--------------------------------------------------------------------------------------------------
sub _materialize {
	my $this = shift;

	$this->_materializeMySQL();
}
#--------------------------------------------------------------------------------------------------
sub _remove {
	my $this = shift;

	$this->_removeMySQL();
}
#--------------------------------------------------------------------------------------------------
sub _generateSessionId  {
	my $this = shift;

	$this->_generateSessionIdMD5();
}
#--------------------------------------------------------------------------------------------------
sub _serialize {
	my $this = shift;
	
	$this->_serializeBase64();
}
#--------------------------------------------------------------------------------------------------
sub _unserialize {
	my $this = shift;

	$this->_unserializeBase64();
}
#--------------------------------------------------------------------------------------------------
sub _checkObsolete {
	my $this = shift;

	if ( time() > ($this->{data}->{_session_atime} + EXPIRE )) {
		$log->info(__PACKAGE__.': Session '.$this->{_session_id}.' is obsolete');
		$this->_rename();
	}
}
#---------------------------------------------------------------------------------------------------------------
#	Store Functions 
#---------------------------------------------------------------------------------------------------------------

sub _insertMySQL {
	my $this    = shift;
 
	if (!defined $this->{insert_sth}) {
	     $this->{insert_sth} = 
		$db->prepare_cached(q/INSERT INTO sessions (id, a_session) VALUES (?,?)/);
	}

	$this->{insert_sth}->bind_param(1, $this->{_session_id});
	$this->{insert_sth}->bind_param(2, $this->{serialized});
	
	$this->{insert_sth}->execute;
	$this->{insert_sth}->finish;
}
#--------------------------------------------------------------------------------------------------
sub _renameMySQL {
	my $this    = shift;
 
	if (!defined $this->{rename_sth}) {
	     $this->{rename_sth} = 
		$db->prepare_cached(q/UPDATE sessions SET id = ? WHERE id = ?/);
	}

	$this->{rename_sth}->bind_param(1, $this->{_session_id});
	$this->{rename_sth}->bind_param(2, $this->{_old_session_id});

	$this->{rename_sth}->execute;
	$this->{rename_sth}->finish;

}
#--------------------------------------------------------------------------------------------------
sub _updateMySQL {
	my $this    = shift;
 
	if (!defined $this->{update_sth}) {
	     $this->{update_sth} = 
		$db->prepare_cached(q/UPDATE sessions SET a_session = ? WHERE id = ?/);
	}

	$this->{update_sth}->bind_param(1, $this->{serialized});
	$this->{update_sth}->bind_param(2, $this->{_session_id});
	
	$this->{update_sth}->execute;
	$this->{update_sth}->finish;
}
#--------------------------------------------------------------------------------------------------
sub _materializeMySQL {
	my $this    = shift;

	if (!defined $this->{materialize_sth}) {
	     $this->{materialize_sth} = 
		$db->prepare_cached(q/SELECT a_session FROM sessions WHERE id = ?/);
	}
    
	$this->{materialize_sth}->bind_param(1, $this->{_session_id});
	$this->{materialize_sth}->execute;
    
	my $results = $this->{materialize_sth}->fetchrow_arrayref;
	$this->{materialize_sth}->finish;
	$this->{serialized} = $results->[0] || '';
    
}
#--------------------------------------------------------------------------------------------------
sub _removeMySQL {
	my $this    = shift;
	
	if (!defined $this->{remove_sth}) {
	     $this->{remove_sth} = 
		$db->prepare_cached(q/DELETE FROM sessions WHERE id = ?/);
	}
	
	$this->{remove_sth}->bind_param(1, $this->{_session_id});
	    
	$this->{remove_sth}->execute;
	$this->{remove_sth}->finish;
}
#---------------------------------------------------------------------------------------------------------------
#	Generate Functions 
#---------------------------------------------------------------------------------------------------------------
sub _generateSessionIdMD5 {
	my $this = shift;

	$this->{_session_id} = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). {}. rand(). $$)), 0, KEY_LENGTH);
}
#---------------------------------------------------------------------------------------------------------------
#	Serialize Functions 
#---------------------------------------------------------------------------------------------------------------
sub _serializeBase64 {
    my $this = shift;

    $this->{serialized} = encode_base64(nfreeze($this->{data}));
}
#--------------------------------------------------------------------------------------------------
sub _unserializeBase64 {
    my $this = shift;

    my $data = thaw(decode_base64($this->{serialized}));
    die "Session could not be unserialized" unless defined $data;
    $this->{data} = $data;
}
#--------------------------------------------------------------------------------------------------

1;
