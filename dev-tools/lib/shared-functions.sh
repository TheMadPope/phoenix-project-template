#!/bin/bash
####################################################################################################
#
# FILENAME:     shared-functions.sh
#
# PURPOSE:      Common header file for all dev-tools scripts. Contains shared functions.
#
# DESCRIPTION:  Contains shared functions used by all of the dev-tools shell scripts.
#
# INSTRUCTIONS: This script should be sourced at the top of all dev-tools shell scripts.
#               Do not source this script manually from the command line. If you do, all of the
#               shell variables set by this script (including those from local-config.sh) will be
#               set in the user's shell, and any changes to local-config.sh may not be picked up
#               until the user manually exits their shell and opens a new one.
#
####################################################################################################

#### PREVENT RELOAD OF THIS LIBRARY ################################################################
if [ "$SFDX_PHOENIX_FRAMEWORK_SHELL_VARS_SET" = "true" ]; then
  # The SFDX_PHOENIX_FRAMEWORK_SHELL_VARS_SET variable is defined as part of
  # this project's local configuration script (local-config.sh).  If this
  # variable holds the string "true" then it means that local-config.sh has
  # already been sourced (loaded).  Since this is exactly what THIS script
  # (shared-functions.sh) is supposed to do it means that this library has
  # already been loaded.
  #
  # We DO NOT want to load shared-functions.sh a second time, so we'll RETURN
  # (not EXIT) gracefully so the caller can continue as if they were the
  # first to load this.
  return 0
fi

#### FUNCTIONS #####################################################################################

#REGION A

askUserForStringValue () {
  # If a second argument was provided, echo its
  # value before asking the user for input.
  if [ "$2" != "" ]; then
    echo $2 "\n"
  fi

  # Create a local variable to store the value of
  # the variable provided by the first argument.
  eval "local LOCAL_VALUE=\$$1"

  # Create a local variable to store the default error message.
  local LOCAL_ERROR_MSG="You must provide a value at the prompt."

  # Do not allow the user to continue unless they
  # provide a value when prompted.
  while [ "$LOCAL_VALUE" = "" ]; do
    eval "read -p \"$1: \" $1"
    eval "LOCAL_VALUE=\$$1"

    if [ "$LOCAL_VALUE" = "" ]; then
      # If the caller specified a custom error message, use it.
      if [ "$3" != "" ]; then
        eval "LOCAL_ERROR_MSG=\"$3\""
      fi
      echoErrorMsg "$LOCAL_ERROR_MSG"
    fi
  done
}

assignPermset () {
  # Assign permission sets to the current user.
  # Pass in the DEVELOPER NAME of the permission set
  local USER=$2
  if [ -z "$2" ]; then
    USER="$SCRATCH_ORG_ALIAS"
  else
    USER="$2"
  fi
  echoStepMsg "Assign the $1 permission set to the current user"
  command="sf org assign permset --name $1 --json"
  echo "Executing: $command"
  json_output=$(cd $PROJECT_ROOT && eval $command)

  status=$(echo "$json_output" | jq -r '.status')
  if [ "$status" != "0" ]; then
    echoErrorMsg "Permission set \"$1\" could not be assigned"
  fi
}

#END REGION A

#REGION B
#END REGION B

#REGION C

confirmChoice () {
  # Local variable will store the user's response.
  local USER_RESPONSE=""
  # Show the question being asked.
  echo "`tput rev`$2`tput sgr0`"
  # Save the user's response to the variable provided by the caller.
  read -p "(type YES to confirm, or hit ENTER to cancel) " USER_RESPONSE
  # Convert USER_RESPONSE to lowercase
  USER_RESPONSE_LOWER=$(echo "$USER_RESPONSE" | tr '[:upper:]' '[:lower:]' )
  # Set possible positive answers
  local confirmationOptions=("yes" "y" "sure" "uh-huh" "yeah" "why not?" "yep" "ok" "*nods*" "nod")
  # Check if the answer given is in the list of possibles
  if [[ " ${confirmationOptions[@]} " =~ " $USER_RESPONSE_LOWER " ]]; then
    eval "$1=true"
  else
    eval "$1=false"
  fi
}

confirmWithAbort () {
  local confirmExecution=false
  confirmChoice confirmExecution "$1"
  if [ "$confirmExecution" = false ] ; then
    echo "Script aborted."
    exit 0
  fi
  echo ""
}

createScratchOrg() {
  # Declare a local variable to store the Alias of the org to CREATE
  local ORG_ALIAS_TO_CREATE=""

  # Check if a value was passed to this function in Argument 1.
  # If there was we will make that the org alias to CREATE.
  if [ ! -z $1 ]; then
    ORG_ALIAS_TO_CREATE="$1"
  elif [ ! -z $TARGET_ORG_ALIAS ]; then
    ORG_ALIAS_TO_CREATE="$TARGET_ORG_ALIAS"
  else
    # Something went wrong. No argument was provided and the TARGET_ORG_ALIAS
    # has not yet been set or is an empty string.  Raise an error message and
    # then exit 1 to kill the script.
    echoErrorMsg "Could not execute createScratchOrg(). Unknown target org alias."
    exit 1
  fi

  # Create a new scratch org using the scratch-def.json locally configured for this project.
  echoStepMsg "Create a new $ORG_ALIAS_TO_CREATE scratch org"
  echo "Executing force:org:create -f $SCRATCH_ORG_CONFIG -a $ORG_ALIAS_TO_CREATE -v $DEV_HUB_ALIAS -s -d 29"
  (cd $PROJECT_ROOT && exec sfdx force:org:create -f $SCRATCH_ORG_CONFIG -a $ORG_ALIAS_TO_CREATE -v $DEV_HUB_ALIAS -s -d 29)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Scratch org \"$ORG_ALIAS_TO_CREATE\"could not be created. Aborting Script."
    exit 1
  fi
}

createTestClassList() {
  folder="./"
  count=0

  # Array to store matching filenames
  matching_filenames=()
  strings_to_match=("@isTest" "@IsTest" "@istest", "@ISTEST")

  ## Find all .cls files in the folder and its subdirectories
  while IFS= read -r -d '' file; do
      # Check if the file contains any string from the array
      for pattern in "${strings_to_match[@]}"; do
          if grep -q "$pattern" "$file"; then
              # Echo the file name without extension
              filename=$(basename -- "$file")
              filename_no_ext="${filename%.*}"
              matching_filenames+=("$filename_no_ext")  # Append to the array
              ((count++))  # Increment the count variable
              break  # Break out of the loop if any pattern is found
          fi
      done
  done < <(find "$folder" -type f -name "*.cls" -print0)


  # Combine array elements into a comma-separated string
  matching_filenames_string=$(IFS=,; echo "${matching_filenames[*]}")
  # Output the matching filenames string to a file
  output_file="./dev-tools/temp/test_classes.txt"
  mkdir -p "$(dirname "$output_file")"  # Create the directory if it doesn't exist
  echo "$matching_filenames_string" > "$output_file"

  echo "Test classes to run: $count"
}

#END REGION C

#REGION D
deleteScratchOrg () {
  # Declare a local variable to store the Alias of the org to delete
  local ORG_ALIAS_TO_DELETE=""

  # Check if a value was passed to this function in Argument 1.
  # If there was we will make that the org alias to delete.
  if [ ! -z $1 ]; then
    ORG_ALIAS_TO_DELETE="$1"
  elif [ ! -z $TARGET_ORG_ALIAS ]; then
    ORG_ALIAS_TO_DELETE="$TARGET_ORG_ALIAS"
  else
    # Something went wrong. No argument was provided and the TARGET_ORG_ALIAS
    # has not yet been set or is an empty string.  Raise an error message and
    # then exit 1 to kill the script.
    echoErrorMsg "Could not execute deleteScratchOrg(). Unknown target org alias."
    exit 1
  fi

  # Delete the current scratch org.
  echoStepMsg "Delete the $ORG_ALIAS_TO_DELETE scratch org"
  echo "Executing force:org:delete -p -u $ORG_ALIAS_TO_DELETE -v $DEV_HUB_ALIAS"
  (cd $PROJECT_ROOT && exec sfdx force:org:delete -p -u $ORG_ALIAS_TO_DELETE -v $DEV_HUB_ALIAS )
}

determineTargetOrgAlias () {
  # Start by clearing TARGET_ORG_ALIAS so we'll know for sure if a new value was provided
  TARGET_ORG_ALIAS=""

  # If no value was provided for $REQUESTED_OPERATION, set defaults and return success.
  if [ -z "$REQUESTED_OPERATION" ]; then
    PARENT_OPERATION="NOT_SPECIFIED"
    TARGET_ORG_ALIAS="NOT_SPECIFIED"
    return 0
  else
    case "$REQUESTED_OPERATION" in
      "REBUILD_SCRATCH_ORG")
        TARGET_ORG_ALIAS="$SCRATCH_ORG_ALIAS"
        ;;
      "VALIDATE_PACKAGE_SOURCE")
        TARGET_ORG_ALIAS="$PACKAGING_ORG_ALIAS"
        ;;
      "DEPLOY_PACKAGE_SOURCE")
        TARGET_ORG_ALIAS="$PACKAGING_ORG_ALIAS"
        ;;
      "INSTALL_PACKAGE")
        TARGET_ORG_ALIAS="$SUBSCRIBER_ORG_ALIAS"
        ;;
    esac
    # Make sure that TARGET_ORG_ALIAS was set.  If not, it means an unexpected PARENT_OPERATION
    # was provided.  In that case, raise an error and abort the script.
    if [ -z "$TARGET_ORG_ALIAS" ]; then
      echo "\nFATAL ERROR: `tput sgr0``tput setaf 1`\"$REQUESTED_OPERATION\" is not a valid installation option.\n"
      exit 1
    fi
    # If we get this far, it means that the REQUESTED_OPERATION was valid.
    # We can now assign that to the PARENT_OPERATION variable and return success.
    PARENT_OPERATION="$REQUESTED_OPERATION"
    return 0
  fi
}

#END REGION D

#REGION E

echo_blank_lines() {
    for ((i = 1; i <= $1; i++)); do
        echo
    done
}

echo_text_black_on_green() {
    echo -e "\e[1;97;42m$1\e[0m"  # Black text on green background
}

echo_text_error() {
    echo -e "\033[31;40mERROR :: $1\033[0m"  # Red text on black background
}

echo_text_green() {
    echo -e "\033[32;40m$1\033[0m"  # Green text on black background
}

echo_text_ok() {
    echo -e "\033[32;40mOK    :: $1\033[0m"  # Green text on black background
}

echo_text_red() {
    echo -e "\033[31;40m$1\033[0m"  # Red text on black background
}

echo_text_white_on_black() {
    echo -e "\e[30;47m$1\e[0m"  # Black text on white background
}

echo_text_white_on_black_bold() {
    echo -e "\e[1;30;47m$1\e[0m"  # Black text on white background, bold
}

echo_text_white_on_red() {
    echo -e "\033[31;41m$1\033[0m"  # Black text on red background
}

echoConfigVariables () {
  echo ""
  echo "`tput setaf 7`PROJECT_ROOT -------------->`tput sgr0` " $PROJECT_ROOT
  echo "`tput setaf 7`NAMESPACE_PREFIX ---------->`tput sgr0` " $NAMESPACE_PREFIX
  echo "`tput setaf 7`PACKAGE_NAME -------------->`tput sgr0` " $PACKAGE_NAME
  echo "`tput setaf 7`DEFAULT_PACKAGE_DIR_NAME -->`tput sgr0` " $DEFAULT_PACKAGE_DIR_NAME
  echo "`tput setaf 7`TARGET_ORG_ALIAS ---------->`tput sgr0` " $TARGET_ORG_ALIAS
  echo "`tput setaf 7`DEV_HUB_ALIAS ------------->`tput sgr0` " $DEV_HUB_ALIAS
  echo "`tput setaf 7`SCRATCH_ORG_ALIAS --------->`tput sgr0` " $SCRATCH_ORG_ALIAS
  echo "`tput setaf 7`PACKAGING_ORG_ALIAS ------->`tput sgr0` " $PACKAGING_ORG_ALIAS
  echo "`tput setaf 7`SUBSCRIBER_ORG_ALIAS ------>`tput sgr0` " $SUBSCRIBER_ORG_ALIAS
  echo "`tput setaf 7`METADATA_PACKAGE_ID ------->`tput sgr0` " $METADATA_PACKAGE_ID
  echo "`tput setaf 7`PACKAGE_VERSION_ID -------->`tput sgr0` " $PACKAGE_VERSION_ID
  echo "`tput setaf 7`SCRATCH_ORG_CONFIG -------->`tput sgr0` " $SCRATCH_ORG_CONFIG
  echo "`tput setaf 7`GIT_REMOTE_URI ------------>`tput sgr0` " $GIT_REMOTE_URI
  echo "`tput setaf 7`ECHO_LOCAL_CONFIG_VARS ---->`tput sgr0` " $ECHO_LOCAL_CONFIG_VARS
  echo ""
}

echoErrorMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nERROR: "
  tput sgr 0; tput setaf 1;
  printf "%b\n\n" "$1"
  tput sgr 0;
}

echoQuestion () {
  tput sgr 0; tput rev;
  printf "\nQuestion $CURRENT_QUESTION of $TOTAL_QUESTIONS:"
  printf " %b\n\n" "$1"
  tput sgr 0;
  let CURRENT_QUESTION++
}

echoScriptCompleteMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nScript Complete: "
  tput sgr 0;
  printf "%b\n\n" "$1"
  tput sgr 0;
}

echoStepMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  if [ $TOTAL_STEPS -gt 0 ]; then
    ## This is one of a sequence of steps
    printf "\nStep $CURRENT_STEP of $TOTAL_STEPS:"
  else
    # This is likely a preliminary step, coming before a sequence.
    printf "\nPreliminary Step $CURRENT_STEP:"
  fi
  tput sgr 0;
  printf " %b\n\n" "$1"
  tput sgr 0;
  let CURRENT_STEP++
}

echoWarningMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nWARNING: "
  tput sgr 0;
  printf "%b\n\n" "$1"
  tput sgr 0;
}

executeAnonymousApex () {
  # Get Apex file path from parameter or ask for it
  filePath="$1"

  # Run anonymous Apex with the Salesforce CLI
  OUTPUT=$(sf apex run --file "$filePath")
  EXIT_CODE="$?"

  # Check Salesforce CLI exit code
  if [ "$EXIT_CODE" -eq 0 ]; then
      # Check for Apex runtime error
      APEX_ERRORS=$(echo "$OUTPUT" | grep 'Error: ')
      if [ "$APEX_ERRORS" != '' ]; then
        # Log errors
        echo "Apex runtime error:"
        echo "$APEX_ERRORS"
        EXIT_CODE=-1;
      else
        # Keep debug log lines only
        OUTPUT=$(echo "$OUTPUT" | grep 'USER_DEBUG')
        # Simplify debug log: keep time stamp, line number and message only
        OUTPUT=$(echo "$OUTPUT" | sed -E 's,([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+) \([0-9]+\)\|USER_DEBUG\|\[([0-9]+)\]\|DEBUG\|(.*),\1\tLine \2\t\3,')
        echo "$OUTPUT"
      fi
  else
      # Salesforce CLI error
      echo "Salesforce CLI failed to execute anonymous Apex:"
      echo "$OUTPUT"
  fi
  echo ""
  exit $EXIT_CODE
}

#END REGION E

#REGION F

findProjectRoot () {
  # Start from the current directory
  current_dir=$(realpath .)

  # Look for the "dev-tools" directory by traversing up the directory structure
  while [[ "$current_dir" != "/" ]]; do
    if [[ -d "$current_dir/dev-tools" ]]; then
      root_dir="$current_dir"
      break
    fi
    current_dir=$(dirname "$current_dir")
  done

  # Check if the "dev-tools" parent directory was found
  if [[ -z "$root_dir" ]]; then
    echo "FATAL ERROR: `tput sgr0``tput setaf 1`Could not find the project root directory (defined as one level UP from the dev-tools folder)."
    echo "FATAL ERROR: `tput sgr0``tput setaf 1`PLEASE NOTE: Scripts must be run from any folder below the dev-tools folder."
    exit 1
  fi
  
  # Pass the value of the "detected path" back out to the caller by setting the
  # value of the first argument provided when the function was called.
  eval "$1=\"$root_dir\""
}

#END REGION F

#REGION G
#END REGION G
#REGION H
#END REGION H

#REGION I

importData () {
  local target_org=$2
  if [ -z "$2" ]; then
    target_org="$SCRATCH_ORG_ALIAS"
  else
    target_org="$2"
  fi
  # Setup development data
  echoStepMsg "Import data from $1"
  command="sf data import tree --target-org $target_org --plan $1"
  echo "Executing: $command"
  (cd $PROJECT_ROOT && exec $command)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Data import failed. Aborting Script."
    exit 1
  fi
}

initializeHelperVariables () {
  CONFIRM_EXECUTION=""                                  # Indicates the user's choice whether to execute a script or not
  PROJECT_ROOT=""                                       # Path to the root of this SFDX project
  TARGET_ORG_ALIAS=""                                   # Target of all Salesforce CLI commands during this run
  LOCAL_CONFIG_FILE_NAME=dev-tools/lib/local-config.sh  # Name of the file that contains local config variables
  CURRENT_STEP=1                                        # Used by echoStepMsg() to indicate the current step
  TOTAL_STEPS=0                                         # Used by echoStepMsg() to indicate total num of steps
  CURRENT_QUESTION=1                                    # Used by echoQuestion() to indicate the current question
  TOTAL_QUESTIONS=1                                     # Used by echoQuestion() to indicate total num of questions

  # Call findProjectRoot() to dynamically determine
  # the path to the root of this SFDX project
  findProjectRoot PROJECT_ROOT
}

installPackage () {
  # Echo the string provided by argument three. This string should provide the
  # user with an easy-to-understand idea of what package is being installed.
  echoStepMsg "$3"
  local TARGET_ORG=$4
  if [ -z "$4" ]; then
    TARGET_ORG="$SCRATCH_ORG_ALIAS"
  else
    TARGET_ORG="$4"
  fi

  command="sf package install --package $1 --publish-wait 5 --wait 10 --target_org $TARGET_ORG"
  echo "Executing: $command"
  
  # Print the time (HH:MM:SS) when the installation started.
  echo "\n`tput bold`Package installation started at `date +%T``tput sgr0`\n"
  local startTime=`date +%s`

  # Perform the package installation.  If the installation fails abort the script.
  (cd $PROJECT_ROOT && exec $command)
  if [ $? -ne 0 ]; then
    echoErrorMsg "$2 could not be installed. Aborting Script."
    exit 1
  fi

  # Print the time (HH:MM:SS) when the installation completed.
  echo "\n`tput bold`Package installation completed at `date +%T``tput sgr0`"
  local endTime=`date +%s`

  # Determine the total runtime (in seconds) and show the user.
  local totalRuntime=$((endTime-startTime))
  echo "Total runtime for package installation was $totalRuntime seconds."
}

#END REGION I

#REGION J
#END REGION J
#REGION K
#END REGION K
#REGION L
#END REGION L
#REGION M
#END REGION M
#REGION N
#END REGION N
#REGION O
#END REGION O

#REGION P

pushMetadata () {
  local target_org=$1
  if [ -z "$1" ]; then
    target_org="$SCRATCH_ORG_ALIAS"
  else
    target_org="$1"
  fi
  # Push metadata to the new Scratch Org.
  echoStepMsg "Push metadata to the new org $target_org"
  command="sf project deploy start --target-org $target_org"
  echo "Executing: $command"
  (cd $PROJECT_ROOT && exec $command)
  if [ $? -ne 0 ]; then
    echoErrorMsg "SFDX source could not be pushed to the scratch org. Aborting Script."
    exit 1
  fi
}

#END REGION P

#REGION Q
#END REGION Q

#REGION R

refreshSandbox () {
    local ORG_TO_USE=$1
    local SANDBOX_NAME=$2
    #echo "ORG_TO_USE: $ORG_TO_USE"
    #echo "SANDBOX_NAME: $SANDBOX_NAME"

    local initialConfirm=false
    confirmChoice initialConfirm "Do you want to refresh this Sandbox? Name: $SANDBOX_NAME?"
    if [ "$initialConfirm" = false ] ; then
        echo "Cancelling Sandbox refresh."
        exit 0
    fi

    # return a json result of
    org="$(sf org display --target-org ${ORG_TO_USE} --json)"

    # parse response
    result="$(echo ${org} | jq -r .result)"
    accessToken="$(echo ${result} | jq -r .accessToken)"
    instanceUrl="$(echo ${result} | jq -r .instanceUrl)"
    id="$(echo ${result} | jq -r .id)"

    # use curl to call the Tooling API and run a query
    query="SELECT+Id,SandboxName+FROM+SandboxInfo+WHERE+SandboxName\=\'${SANDBOX_NAME}\'"
    http="${instanceUrl}/services/data/v40.0/tooling/query/\?q\=${query}"
    flags="-H 'Authorization: Bearer ${accessToken}'"
    result=$(eval curl $http $flags --silent)

    records="$(echo ${result} | jq -r .records)"
    sandboxName="$(echo ${records} | jq -r .[0].SandboxName)"
    sandboxId="$(echo ${records} | jq -r .[0].Id)"

    local confirmRefresh=false
    confirmChoice confirmRefresh "Do you really truly want to refresh this Sandbox? Name: $sandboxName; Id: $sandboxId???"
    if [ "$confirmRefresh" = false ] ; then
        echo "Cancelling Sandbox refresh."
        exit 0
    fi

    echo "Executing Sandbox refresh..."
    # use curl to refresh the sandbox
    response=$(curl -X PATCH -H "Content-Type: application/json" -H "Authorization: Bearer $accessToken" -d '{"AutoActivate": true, "LicenseType": "DEVELOPER"}' "$instanceUrl/services/data/v40.0/tooling/sobjects/SandboxInfo/$sandboxId")
    echo $response
    echo "This should be going now. Go get some coffee and check back later!"

    exit 0
}

replaceText () {
    # Check if all three required arguments are provided
    if [[ $# -lt 3 ]]; then
        echo "Usage: $0 <file_path> <string_to_find> <new_string> [<suppress_echo>]"
        exit 1
    fi

    # Check if the file exists
    if [[ ! -f $1 ]]; then
        echo "Error: File '$1' does not exist."
        exit 1
    fi

    # Replace all occurrences of the string in the file and save the updated file IN PLACE
    # NOTE: The optional sed parameter of the output file causes issues when replacing multiple values
    sed -i "s/$2/$3/gI" "$1"

    if [[ "$4" != -s ]]; then
        echo "Replaced all occurences of '$2' with '$3'."
    fi
}

resetQuestionCounter () {
  CURRENT_QUESTION=1
  TOTAL_QUESTIONS=$1
}

resetStepMsgCounter () {
  CURRENT_STEP=1
  TOTAL_STEPS=$1
}

showPressAnyKeyPrompt () {
  read -n 1 -sr -p "-- Press any Key to Continue --"
}

#END REGION R

#REGION S

suggestDefaultValue () {
  # Make sure a value was provided for the
  # second argument of this function.
  if [ "$2" = "" ]; then
    echoErrorMsg "You must provide two arguments to suggestDefaultValue.  Terminating script."
    exit 1
  fi

  # Create local variables to store the value of
  # the variable provided by the first argument and the
  # value of the second argument (proposed default)
  eval "local LOCAL_VALUE=\$$1"
  eval "local LOCAL_DEFAULT=\"$2\""

  # Set a defualt prompt message in case one is not provided.
  local INTERNAL_USER_PROMPT="Would you like to accept the following default value?"

  # If the caller supplied a third argument, it means they want
  # a specific message to be shown before accepting the default.
  # If they did now, we will use owr own "default" message.
  if [ ! -z "$3" ]; then
    INTERNAL_USER_PROMPT="$3"
  fi

  # Show prompt and display what the default var assignment would be.
  echo $INTERNAL_USER_PROMPT
  echo "\n"$1=$LOCAL_DEFAULT"\n"

  # Ask user to confirm or reject the proposed value.
  local ACCEPT_DEFAULT=""
  read -p "(type YES to accept,  NO to provide a different value) " ACCEPT_DEFAULT
  if [ "$ACCEPT_DEFAULT" != "YES" ]; then
    return 1
  fi

  # Store the value from arg 2 into arg 1, basically
  # using the "default" value for the main value.
  eval "$1=\"$2\""

  return 0
}

#END REGION S

#REGION T
#END REGION T
#REGION U
#END REGION U
#REGION V
#END REGION V
#REGION W
#END REGION W
#REGION X
#END REGION X
#REGION Y
#END REGION Y
#REGION Z
#END REGION Z

#### BEGIN MAIN EXECUTION BLOCK ####################################################################
# INITIALIZE HELPER VARIABLES
initializeHelperVariables

# CHECK IF LOCAL CONFIG SHOULD BE SUPPRESSED.
# If $SUPPRESS_LOCAL_CONFIG has been set to "true" DO NOT load the local configuration
# variables.  A script that includes shared-functions.sh can set this variable to
# force this behavior (dev-tools/setup-core-project for example).
if [ "$SUPPRESS_LOCAL_CONFIG" = "true" ]; then
  # Comment out the following line unless you're debugging setup-core-project.
  # echo "Local dev-tools configuration (local-config.sh) has been suppressed"
  return 0
fi

# CHECK IF LOCAL CONFIG FILE EXISTS
# Look for the local config variables script local-config.sh.  If the developer has not created a
# local-config.sh file in dev-tools/lib then EXIT from the shell script with an error message.
if [ ! -r "$PROJECT_ROOT/$LOCAL_CONFIG_FILE_NAME" ]; then
  echoErrorMsg "Local dev-tools configuration file not found"
  tput sgr 0; tput bold;
  echo "Please create a local-config.sh file in your dev-tools/lib directory by copying"
  echo "dev-tools/templates/local-config-template.sh and customizing it with your local settings\n"
  exit 1
fi

# LOAD THE LOCAL CONFIG VARIABLES
# The local-config.sh file was found and is readable. Source (execute) it the current shell process.
# This will make all the variables defined in local-config.sh available to all commands that come
# after it in this shell.
source "$PROJECT_ROOT/$LOCAL_CONFIG_FILE_NAME"

# MARK THAT LOCAL CONFIG VARIABLES HAVE BEEN SET.
# Indicates that local config variables have been successfully set.
SFDX_PHOENIX_FRAMEWORK_SHELL_VARS_SET="true"

##END##
