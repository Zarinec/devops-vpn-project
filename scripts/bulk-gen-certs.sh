#!/bin/bash
for user in $(cat users.list); do
./scripts/gen-client-cert.sh "$user"
done
   
