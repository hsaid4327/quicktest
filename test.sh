#!/bin/bash

 while true; 
   do echo "listening on port 9447"; 
   nc -k -l 9447; 
 done
