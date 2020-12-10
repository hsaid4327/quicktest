#!/bin/bash

 while true; 
   do echo "listening 3 on port 9477"; 
   nc -k -l --recv-only 9477; 
 done
