#!/bin/bash

echo "###############################################################################"
echo "#  MAKE SURE YOU ARE LOGGED IN:                                               #"
echo "#  $ oc login http://<api-url>                                                #"
echo "###############################################################################"

function usage() {
    echo "Usage:"
    echo " $0 [command] [options]"
    echo " $0 --help"
    echo
    echo "Example:"
    echo " $0 deploy --project-name mydemo --app-name appname --image-name demo-image --image-tag demov1 --app-name demo-app"

    echo " $0 delete --project-name mydemo--app-name demoapp"
    echo
    echo "COMMANDS:"
    echo "   deploy                   Create the application deployment in a given project"
    echo "   delete                   Clean up and application resources from the project"
    echo
    echo "OPTIONS:"


    echo "   --app-name                required application name for the deployment artifact and openshift resources."
 
    echo "   --project-name [suffix]    required project name in which application is to be deployed"
    
    echo "   --image-name required   name of image"
    echo "   --image-tag required   tag of image"

}


ARG_COMMAND=
PROJECT_NAME=

APP_NAME=
NUM_ARGS=$#
AGENT_KEY=
IMAGE_NAME=
IMAGE_TAG=

echo "The number of shell arguments is $NUM_ARGS"

while :; do
    case $1 in
        deploy)
            ARG_COMMAND=deploy
            if [ "$NUM_ARGS" -lt 9 ]; then
              printf 'ERROR: "--the number of arguments cannot be less than 4 for deploy command" \n' >&2
              usage
              exit 255
            fi
            ;;
        delete)
            ARG_COMMAND=delete
            if [ "$NUM_ARGS" -lt 4 ]; then
              printf 'ERROR: "--the number of arguments cannot be less than 3 for deploy command" \n' >&2
              usage
              exit 255
            fi
            ;;


        --project-name)
            if [ -n "$2" ]; then
                PROJECT_NAME=$2
                shift
            else
                printf 'ERROR: "--project-suffix" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --app-name)
            if [ -n "$2" ]; then
                APP_NAME=$2
		echo "ARG_APP_NAME: $ARG_APP_NAME"
                shift
            else
                printf 'ERROR: "--arg-app-name" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;

 

	  --image-name)
            if [ -n "$2" ]; then
                IMAGE_NAME=$2
                shift
            else
                printf 'ERROR: "--agent-key" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
	  --image-tag)
            if [ -n "$2" ]; then
                IMAGE_TAG=$2
                shift
            else
                printf 'ERROR: "--agent-key" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;

        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *) # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done
 if [ -z $PROJECT_NAME ]; then
    usage
    exit 255
 fi



DEPLOY_TEMPLATE="quicktest-deploy-template"
PROJECT_STAGE="hsaid-app-1"
AVAYA_COMMON="hsaid-quicktest-common"


function setup_projects() {
  echo_header "Setting up project"

  projectExists=$(oc projects | grep $PROJECT_NAME)
  echo "projectExists: $projectExists"
  if [ -z $projectExists ]; then
     oc new-project $PROJECT_NAME
     echo_header "Project created"
  else
     oc project $PROJECT_NAME
  fi

   oc adm policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME -n $AVAYA_COMMON
   oc adm policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME -n $PROJECT_STAGE



  
}

function setup_applications() {
  echo_header "Setting up Openshift application resources in $PROJECT_NAME"
  oc new-app --template $AVAYA_COMMON/$DEPLOY_TEMPLATE -p APP_NAME=$APP_NAME -p IMAGE_NAME=$IMAGE_NAME -p IMAGE_TAG=$IMAGE_TAG  -n $PROJECT_NAME
  sleep 5
  oc tag $PROJECT_STAGE/$IMAGE_NAME:latest $PROJECT_NAME/$IMAGE_NAME:$IMAGE_TAG
}

function echo_header() {
  echo
  echo "########################################################################"
  echo "$1"
  echo "########################################################################"
}


function delete_setup() { 
   echo "APP_NAME: $APP_NAME"
   echo_header "Deleting project resources"
 
   oc adm policy  remove-role-from-group edit system:serviceaccounts:$PROJECT_NAME -n $PROJECT_STAGE

   oc adm policy  remove-role-from-group edit system:serviceaccounts:$PROJECT_NAME -n $AVAYA_COMMON
   
   oc delete all -l app=$APP_NAME -n $PROJECT_NAME
   oc delete pvc $APP_NAME-pvc -n $PROJECT_NAME
 
}

START=`date +%s`


echo_header "Avaya CICD pipeline deployment ($(date))"

case "$ARG_COMMAND" in
    delete)
        echo "Delete demo..."
     if [ -z $APP_NAME ]; then
	    usage
	    exit 255
     fi
	delete_setup
        echo "Delete completed successfully!"
        ;;
      


    deploy)
        
       if [ -z $IMAGE_NAME ]; then
            echo "image name is missing"
	    usage
	    exit 255
       fi
	
       if [ -z $IMAGE_TAG ]; then
            echo "image tag is missing"
	    usage
	    exit 255
       fi
       
 

       if [ -z $APP_NAME ]; then
           echo "app name is missing"
	    usage
	    exit 255
        fi
        
        echo "Deploying demo..."
        setup_projects
        echo
        echo "project setup completed successfully!"
        echo "setting up application artifacts ......."
        setup_applications
        echo "setting up applications completed successfully"
        ;;

    *)
        echo "Invalid command specified: '$ARG_COMMAND'"
        usage
        ;;
  esac


END=`date +%s`
echo "(Completed in $(( ($END - $START)/60 )) min $(( ($END - $START)%60 )) sec)"
