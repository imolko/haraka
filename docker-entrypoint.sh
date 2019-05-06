#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
	if [ "$HARAKA_DEBUG" = true ]; then
		echo "Run haraka debug on"
		set -- haraka_debug "$@"
	else
		echo "Run haraka debug off"
		set -- haraka "$@"
	fi

fi

if [ "$1" = 'haraka' ] || [ "$1" = 'haraka_debug' ]; then
	echo "seteamos permisos"
	chmod -R 0777 /haraka
	#chown -R haraka:haraka /haraka

	if [ ! -z "$TARISHI_ME" ]; then
		echo "$TARISHI_ME" > "/haraka/config/me"
	fi

	exec gosu haraka:haraka "$@"
fi

exec "$@"