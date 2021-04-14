#!/bin/bash
 n=0
 while ((n -lt 50)); 
   do echo "in the post deployment hook"
   ((n=n+1))
   sleep 20
 done
