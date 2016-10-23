package Cfg;
use strict;

BEGIN {
    use Exporter ();

    our ( @ISA, @EXPORT, @EXPORT_OK );

    @ISA       = qw( Exporter );
    @EXPORT    = qw( $cfg );
    @EXPORT_OK = qw( $Logger );

    our $host =  $ENV{HTTP_HOST};

    unless( $host ){ ( undef, undef, undef, $host ) = split( /\//, $0 ,5); }

    our $path = '/var/www/'.$host.'/';

    our ( $path_html, $path_var, $sname ) = ( $path.'html/', $path.'var/', $host );
    $sname =~ s/www\.|\.com|\.net|\.ua|\.ru|\.kiev|\.cn|\.in|\.ssh|\/|\-//mg;

    our %cfg = (
        DB =>
        {
            'host'                 => 'localhost',
            'name'                 => $sname,
            'user'                 => $sname,
            'pass'                 => 'jousushow',
        },

        PATH =>
        {
            'root'                 => $path,
            'ext'                  => $path_var.'ext/',
            'log'                  => $path_var.'log/',
            'gallery'              => $path_var.'gallery/',
            'templates'            => $path_html,
            'tmp'                  => '/tmp/',
        },

        price =>{
      		'root'                  => $path_var.'prices/',
      		'csv'                   => $path_var.'prices/csv/',
      		'xls'                   => $path_var.'prices/xls/',
      		'xlsx'                  => $path_var.'prices/xls/',
  		},

        temp =>
        {
            'TAG_STYLE'            => 'html',
            'css'	               => $sname,
	        'css_file'	           => $path_html.'frontoffice/public/css/'.$sname.'.css',
            'css_file_start'       => $path_html.'frontoffice/public/css/start_'.$sname.'.css',
            'html_file'            => $path_html.'frontoffice/frontoffice/templates/',
    	    'logo'	               => $sname.'logo',
    	    'ico'	               => $sname.'icon.jpg',
    	    'name'                 => $sname,
    	    'host'                 => $host,
            'base_dir'             => $path,
            'price_cur'            => 'UAH',
    	    'price_coin'           => '2',
            'top_menu'             => '1',
            'next_products_limit'  => '22',
            'VARIABLES'            => {  version => '0.1' },

        },

        stt =>
        {
            'TAG_STYLE'            => 'html',
            'OUTPUT_PATH'          => $path_var."html/",
            'INCLUDE_PATH'         => $path_html,
            'VARIABLES'            => {  version => '0.1' },
        },

        stt_catalog =>
        {
    		'TAG_STYLE'            => 'html',
    		'OUTPUT_PATH'          => $path_var.'ext/',
    		'INCLUDE_PATH'         => $path_html,
    		'HOST'                 => 'http://'.$host.'/',
    		'VARIABLES'            => {  version => '0.1' },
        },

        stt_sitemap =>
        {
            'TAG_STYLE'            => 'html',
            'OUTPUT_PATH'          => $path_var."mog30zig/",
            'INCLUDE_PATH'         => $path_html,
            'directory'            => "mog30zig",
            'VARIABLES'            => {  version => '0.1' },
        },

    	clients =>
        {
            required =>
            {
                quick_order =>
                {
                    'clientName'   => '[\d| |-|\w|\S]+',
        			'clientPhone'  => '[\d| |-|\w|\S]+',
        			'comment'      => '[\w| |-|\d|\S]+',
                },
        	},
    		may_save =>
            {
                'quick_order'      => [ 'clientName','clientPhone','comment','clientEmail' ]
            },
    	    'email_from'           => 'admin@ssh.in.ua'
        },

        orders          => {'status_closed_string' => '"closed","rejected","archived","sold"' },
        benchmark       => {'file'                 => '/tmp/benchmark.log' },
        ip_wite_list    => { },

    	mail            =>
    	{
    		'from'          => '<root@'.$host.'>',
    		'publidomain'   => 'http://'.$host.'/',
    		'templates'     => $path_html.'frontoffice/templates/mail/',
    		'send_limit'    => '10',
    	},

      	sphinx =>
      	{
          	  host        => 'localhost',
          	  port        => '9312',
          	  weight      =>  {  id      => '10000',  mpn     => '10000',   name    => '1000',   sdesc   => '100',   sdescf  => '10',  },
              name_index  => $sname.'_salemods',
        	  pname_index => $sname.'_salemods',
        	  test_index  => 'db_n'.$sname,
              aname_index => '',
          	  bname_index => '',
          	  cname_index => ''

      	},
      	gallery 			 => { 'save_format' => 'jpg' },
      	salemods_on_page     => {  options  =>  {     12  => 1,  3600  => 1,   100 => 1,   546 => 1, }, default     => 124 },
        disable_filters_mask => 0,
        A         => ' \\_ \\w \\d \\- \\+ \\( \\) \\: \\, \\. ',
        pkg                  => '/var/www/adata/etc/modules.ini'
    );

    our $cfg = \%cfg;

    sub get_cfg() { 
        return "/var/log/www/$host.debug.log"; 
    }

    our $Logger = q(
        log4perl.category.Core.Logger       = ERROR, Logfile
        log4perl.appender.Logfile           = Log::Log4perl::Appender::File
        log4perl.appender.Logfile.filename  = sub { return Cfg->get_cfg(); }
        log4perl.appender.Logfile.autoflush = 1
        log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Logfile.layout.ConversionPattern = [%p] %d \(+%r\) %m%n
        log4perl.appender.Syncer            = Log::Log4perl::Appender::Synchronized
        log4perl.appender.Syncer.appender   = Logfile
    );

    undef $path_html;
    undef $path_var;
    undef $sname;
    undef $path;
}

1;
