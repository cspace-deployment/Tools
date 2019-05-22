use Digest::MD5 qw(md5 md5_hex md5_base64);

$string = '12345678910';

print md5_hex($string) . "\n";  # human-readable

print md5_base64($string) . "\n";  # human-readable too
