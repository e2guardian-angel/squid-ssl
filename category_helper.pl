#!/usr/bin/perl -wl

require 'shellwords.pl';
use REST::Client;
use JSON;

$client = REST::Client->new();
$url = sprintf("http://%s:%d/lookupip", $ENV{'GUARDIAN_HOSTNAME'}, $ENV{'GUARDIAN_PORT'});

$|=1;

while (<>) {

    ($ip,$category) = &shellwords;

    if (&matches($ip,$category)) {

        print "OK";

    } else {

        print "ERR";

    }

}



sub matches {

    $client->POST($url, sprintf('{"ip":"%s","category":"%s"}', $ip, $category), { "Content-type" => 'application/json'});
    $response = from_json($client->responseContent());
    return $response->{'match'};

}
