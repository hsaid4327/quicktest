#!/bin/bash
 n=0
 while (( n < 50 )); 
   do echo "in the post deployment hook"
   ((n=n+1))
   echo "key1=$key1"
   echo "key1=$KEY1"
   echo "key2=$KEY2"
   sleep 20
 done
