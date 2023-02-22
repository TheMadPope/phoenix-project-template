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
#
####################################################################################################
#
##
###
#### PREVENT RELOAD OF THIS LIBRARY ################################################################
###
##
#
if [ "$SFDX_FALCON_FRAMEWORK_SHELL_VARS_SET" = "true" ]; then
  # The SFDX_FALCON_FRAMEWORK_SHELL_VARS_SET variable is defined as part of
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
#
##
###
#### FUNCTION: askUserForStringValue ###############################################################
###
##
#
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
#
##
###
#### FUNCTION: confirmChoice #######################################################################
###
##
#
confirmChoice () {
  # Local variable will store the user's response.
  local USER_RESPONSE=""
  # Show the question being asked.
  echo "`tput rev`$2`tput sgr0`"
  # Save the user's response to the variable provided by the caller.
  local confirmationOptions=("yes" "y" "sure" "uh-huh" "yeah" "why not?" "yep" "ok" "*nods*" "nod")
  read -p "(type YES to confirm, or hit ENTER to cancel) " USER_RESPONSE
  if [[ " ${confirmationOptions[@]} " =~ " $USER_RESPONSE " ]]; then
    eval "$1=true"
  else
    eval "$1=false"
  fi
}
#
##
###
#### FUNCTION: confirmScriptExecution ##############################################################
###
##
#
confirmWithAbort () {
  local confirmExecution=false
  confirmChoice confirmExecution "$1"
  if [ "$confirmExecution" = false ] ; then
    echo "Script aborted."
    exit 0
  fi
  echo ""
}
#
##
###
#### FUNCTION: createScratchOrg () #################################################################
###
##
#
createScratchOrg() {
  # Set default scratch config or use the one passed in
  local SCRATCH_CONFIG=$1
  if [ -z "$1" ]; then
    SCRATCH_CONFIG="$SCRATCH_ORG_CONFIG"
  else
    SCRATCH_CONFIG="$1"
  fi

  # Set default org alias to use use the one passed in
  local ORG_ALIAS=$2
  if [ -z "$2" ]; then
    ORG_ALIAS="$SCRATCH_ORG_ALIAS"
  else
    ORG_ALIAS="$2"
  fi

  # Create a new scratch org using the specified or default alias and config.
  echoStepMsg "Create a new scratch org with alias: $ORG_ALIAS"
  echo "Executing force:org:create -f $SCRATCH_CONFIG -a $ORG_ALIAS -v $DEV_HUB_ALIAS -s -d 29"
  (cd $PROJECT_ROOT && exec sfdx force:org:create -f $SCRATCH_CONFIG -a $ORG_ALIAS -v $DEV_HUB_ALIAS -s -d 29)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Scratch org could not be created. Aborting Script."
    exit 1
  fi
}
#
##
###
#### FUNCTION: deleteScratchOrg () #################################################################
###
##
#
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
#
##
###
#### FUNCTION: determineTargetOrgAlias () ##########################################################
###
##
#
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
#
##
###
#### FUNCTION: echoConfigVariables () ##############################################################
###
##
#
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
#
##
###
#### FUNCTION: assignPermset () ####################################################################
###
##
#
assignPermset () {
  # Assign permission sets to the scratch org's Admin user.
  # Pass in the DEVELOPER NAME of the permission set, OR a comma seperated list of developer names
  local USER=$2
  if [ -z "$2" ]; then
    USER="$SCRATCH_ORG_ALIAS"
  else
    USER="$2"
  fi
  echoStepMsg "Assign the $1 permission set to the user $USER"
  echo \
  "Executing force:user:permset:assign \\
              --permsetname "$1" \\
              --targetusername $USER \\
              --loglevel error\n"
  (cd $PROJECT_ROOT && exec sfdx force:user:permset:assign \
                                  --permsetname "$1" \
                                  --targetusername $USER \
                                  --loglevel error)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Permission set(s) \"$1\" could not be assigned to the user $USER"
    # Continue regardless, we probably want the rest of the process to complete
  fi
}
#
##
###
#### FUNCTION: createScratchOrg () #################################################################
###
##
#
createScratchOrg() {
  local SCRATCH_CONFIG=$1
  # Set default scratch config
  if [ -z "$1" ]; then
    SCRATCH_CONFIG="$SCRATCH_ORG_CONFIG"
  else
    SCRATCH_CONFIG="$1"
  fi
  local ORG_ALIAS=$2
  # Set default org alias
  if [ -z "$2" ]; then
    ORG_ALIAS="$SCRATCH_ORG_ALIAS"
  else
    ORG_ALIAS="$2"
  fi
  # Create a new scratch org using the scratch-def.json locally configured for this project.
  echoStepMsg "Create a new scratch org with alias: $ORG_ALIAS"
  echo "Executing force:org:create -f $SCRATCH_CONFIG -a $ORG_ALIAS -v $DEV_HUB_ALIAS -s -d 29"
  (cd $PROJECT_ROOT && exec sfdx force:org:create -f $SCRATCH_CONFIG -a $ORG_ALIAS -v $DEV_HUB_ALIAS -s -d 29)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Scratch org could not be created. Aborting Script."
    exit 1
  fi
}
#
##
###
#### FUNCTION: deleteScratchOrg () #################################################################
###
##
#
deleteScratchOrg () {
  local ORG_ALIAS=$1
  # Set default org alias
  if [ -z "$1" ]; then
    ORG_ALIAS="$SCRATCH_ORG_ALIAS"
  else
    ORG_ALIAS="$1"
  fi
  local confirmDelete=false
  confirmChoice confirmDelete "Do you want to delete your existing scratch org with alias: $ORG_ALIAS?"
  if [ "$confirmDelete" = false ] ; then
    return
  fi
  # Delete the current scratch org.
  echoStepMsg "Delete the $ORG_ALIAS scratch org"
  echo "Executing force:org:delete -p -u $ORG_ALIAS -v $DEV_HUB_ALIAS"
  (cd $PROJECT_ROOT && exec sfdx force:org:delete -p -u $ORG_ALIAS -v $DEV_HUB_ALIAS )
}
#
##
###
#### FUNCTION: importData () #######################################################################
###
##
#
importData () {
  local USER=$2
  if [ -z "$2" ]; then
    USER="$SCRATCH_ORG_ALIAS"
  else
    USER="$2"
  fi
  # Setup development data
  echoStepMsg "Import data from $1"
  echo \
  "Executing force:data:tree:import \\
              --plan \"$1\" \\
              --targetusername $USER \\
              --loglevel error)\n"
  (cd $PROJECT_ROOT && exec sfdx force:data:tree:import \
                                  --plan "$1" \
                                  --targetusername $USER \
                                  --loglevel error)
  if [ $? -ne 0 ]; then
    echoErrorMsg "Data import failed. Aborting Script."
    exit 1
  fi
}
#
##
###
#### FUNCTION: installPackage () ###################################################################
###
##
#
installPackage () {
  # Echo the string provided by argument three. This string should provide the
  # user with an easy-to-understand idea of what package is being installed.
  echoStepMsg "$3"
  local USER=$4
  if [ -z "$4" ]; then
    USER="$SCRATCH_ORG_ALIAS"
  else
    USER="$4"
  fi

  # Print the time (HH:MM:SS) when the installation started.
  echo "Executing force:package:install -i $1 -p 5 -w 10 -u $USER"
  echo "\n`tput bold`Package installation started at `date +%T``tput sgr0`\n"
  local startTime=`date +%s`

  # Perform the package installation.  If the installation fails abort the script.
  (cd $PROJECT_ROOT && exec sfdx force:package:install -i $1 -p 5 -w 10 -u $USER)
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
#
##
###
#### FUNCTION: isDevHub () ###################################################################
###
##
#
isDevHub(){
  # return a json result of
  org="$(sfdx force:org:display -u ${DEV_HUB_ALIAS} --json)"

  # parse response
  result="$(echo ${org} | jq -r .result)"
  accessToken="$(echo ${result} | jq -r .accessToken)"
  instanceUrl="$(echo ${result} | jq -r .instanceUrl)"
  id="$(echo ${result} | jq -r .id)"

  # use curl to call the Tooling API and run a query
  query="SELECT+DurableId,+SettingValue+FROM+OrganizationSettingsDetail+WHERE+SettingName+\=+\'ScratchOrgManagementPref\'"
  http="${instanceUrl}/services/data/v40.0/tooling/query/\?q\=${query}"
  flags="-H 'Authorization: Bearer ${accessToken}'"
  hub=$(eval curl $http $flags --silent)

  # parse response
  size="$(echo ${hub} | jq -r .size)"

  if [[ $size -eq 0 ]];
  then
    echo "${id} is not a dev hub"
    exit 0
  fi

  records="$(echo ${hub} | jq -r .records)"
  value="$(echo ${records} | jq -r .[].SettingValue)"

  # evaluate the setting value
  if $value === 'true'
  then
    echo "${id} is a dev hub"
  else
    echo "${id} is not a dev hub"
  fi

exit 0
}
#
##
###
#### FUNCTION: echoErrorMsg () #####################################################################
###
##
#
echoErrorMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nERROR: "
  tput sgr 0; tput setaf 1;
  printf "%b\n\n" "$1"
  tput sgr 0;
}
#
##
###
#### FUNCTION: echoQuestion () #####################################################################
###
##
#
echoQuestion () {
  tput sgr 0; tput rev;
  printf "\nQuestion $CURRENT_QUESTION of $TOTAL_QUESTIONS:"
  printf " %b\n\n" "$1"
  tput sgr 0;
  let CURRENT_QUESTION++
}
#
##
###
#### FUNCTION: echoScriptCompleteMsg () ############################################################
###
##
#
echoScriptCompleteMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nScript Complete: "
  tput sgr 0;
  printf "%b\n\n" "$1"
  tput sgr 0;
}
#
##
###
#### FUNCTION: echoStepMsg () ######################################################################
###
##
#
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
#
##
###
#### FUNCTION: echoWarningMsg () ###################################################################
###
##
#
echoWarningMsg () {
  tput sgr 0; tput setaf 7; tput bold;
  printf "\n\nWARNING: "
  tput sgr 0;
  printf "%b\n\n" "$1"
  tput sgr 0;
}
#
##
###
#### FUNCTION: findProjectRoot () ##################################################################
###
##
#
findProjectRoot () {
  # Detect the path to the directory that the running script was called from.
  local PATH_TO_RUNNING_SCRIPT="$( cd "$(dirname "$0")" ; pwd -P )"

  # Grab the last 10 characters of the detected path.  This should be "/dev-tools".
  local DEV_TOOLS_SLICE=${PATH_TO_RUNNING_SCRIPT: -10}

  # Make sure the last 10 chars of the path are "/dev-tools".
  # Kill the script with an error if not.
  if [[ $DEV_TOOLS_SLICE != "/dev-tools" ]]; then
    echoErrorMsg "Script was not executed within the <project-root>/dev-tools directory."
    tput sgr 0; tput bold;
    echo "Shell scripts that utilize FALCON Developer Tools must be executed from"
    echo "inside the dev-tools directory found at the root of your SFDX project.\n"
    exit 1
  fi

  # Calculate the Project Root path by going up one level from the path currently
  # held in the PATH_TO_RUNNING_SCRIPT variable
  local PATH_TO_PROJECT_ROOT="$( cd "$PATH_TO_RUNNING_SCRIPT" ; cd .. ; pwd -P )"

  # Pass the value of the "detected path" back out to the caller by setting the
  # value of the first argument provided when the function was called.
  eval "$1=\"$PATH_TO_PROJECT_ROOT\""
}
#
##
###
#### FUNCTION: initializeHelperVariables () ########################################################
###
##
#
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
#
##
###
#### FUNCTION: installPackage () ###################################################################
###
##
#
installPackage () {
  # Delcare a local variable to store the Alias of the target install org.
  local PACKAGE_INSTALL_TARGET_ALIAS=""

  # Check if a target org was provided as the FOURTH argument.  If there
  # is no FOURTH argument, go with whatever is set in the TARGET_ORG_ALIAS
  # variable.  If that is empty, then exit with an error.
  if [ ! -z $4 ]; then
    PACKAGE_INSTALL_TARGET_ALIAS="$4"
  elif [ ! -z $TARGET_ORG_ALIAS ]; then
    PACKAGE_INSTALL_TARGET_ALIAS="$TARGET_ORG_ALIAS"
  else
    # Something went wrong. No FOURTH argument was provided and the TARGET_ORG_ALIAS
    # has not yet been set or is an empty string.  Raise an error message and
    # then exit 1 to kill the script.
    echoErrorMsg "Could not execute installPackage(). Unknown target org alias."
    exit 1
  fi

  # Echo the string provided by argument three. This string should provide the
  # user with an easy-to-understand idea of what package is being installed.
  echoStepMsg "$3"

  # Print the time (HH:MM:SS) when the installation started.
  echo "Executing force:package:install --package $1 --publishwait 5 --wait 10 -u $PACKAGE_INSTALL_TARGET_ALIAS"
  echo "\n`tput bold`Package installation started at `date +%T``tput sgr0`\n"
  local startTime=`date +%s`

  # Perform the package installation.  If the installation fails abort the script.
  (cd $PROJECT_ROOT && exec sfdx force:package:install --package $1 --publishwait 5 --wait 10 -u $PACKAGE_INSTALL_TARGET_ALIAS)
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
#
##
###
#### FUNCTION: pushMetadata () #####################################################################
###
##
#
pushMetadata () {
  local USER=$1
  if [ -z "$1" ]; then
    USER="$SCRATCH_ORG_ALIAS"
  else
    USER="$1"
  fi
  # Push metadata to the new Scratch Org.
  echoStepMsg "Push metadata to the new org $USER"
  echo "Executing force:source:push -u $USER"
  (cd $PROJECT_ROOT && exec sfdx force:source:push -u $USER)
  if [ $? -ne 0 ]; then
    echoErrorMsg "SFDX source could not be pushed to the scratch org. Aborting Script."
    exit 1
  fi
}
#
##
###
#### FUNCTION: resetQuestionCounter () #############################################################
###
##
#
resetQuestionCounter () {
  CURRENT_QUESTION=1
  TOTAL_QUESTIONS=$1
}
#
##
###
#### FUNCTION: resetStepMsgCounter () ##############################################################
###
##
#
resetStepMsgCounter () {
  CURRENT_STEP=1
  TOTAL_STEPS=$1
}
#
##
###
#### FUNCTION: showPressAnyKeyPrompt ###############################################################
###
##
#
showPressAnyKeyPrompt () {
  read -n 1 -sr -p "-- Press any Key to Continue --"
}
#
##
###
#### FUNCTION: suggestDefaultValue #################################################################
###
##
#
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
#
##
###
#### FUNCTION: refreshSandbox #################################################################
###
##
#
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
    org="$(sfdx force:org:display -u ${ORG_TO_USE} --json)"

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
#
##
###
#### BEGIN MAIN EXECUTION BLOCK ####################################################################
###
##
#
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
SFDX_FALCON_FRAMEWORK_SHELL_VARS_SET="true"


##END##