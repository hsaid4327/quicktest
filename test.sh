#!/bin/bash

 while true; 
   do echo "listening times:6 on port 9477"; 
   nc -k -l --recv-only 9477; 
 done
