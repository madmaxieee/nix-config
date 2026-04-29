#!/usr/bin/env bash

# shellcheck disable=SC2016
exec expect -c '
	spawn ssh linode -t hermes;
	set pass_val [exec pass linode/madmax];
	expect "password for";
	send "$pass_val\r";
	interact;
'
