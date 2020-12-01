#!/bin/bash

 while true; 
   do echo "listening on port 9447"; 
   nc -k -l --recv-only 9477; 
 done
