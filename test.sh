#!/bin/bash

 while true; 
   do echo "listening 1 on port 9477"; 
   nc -k -l --recv-only 9477; 
 done
