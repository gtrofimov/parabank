#!/bin/bash

COMMAND=$(basename "$0")
printf "%s: -- Copyright (C) 2019 Parasoft Corporation\n\n" $COMMAND

function printHelp {
    echo "Usage: " $COMMAND " [options]

Options:

-help
    Shows help information and does not execute any tests.

-server %SERVER_URL%
    The SOAtest server URL
    Default is https://localhost:9443

-auth %USERNAME:PASSWORD%
    The username and password to use for authentication with the server.
    Default is no authentication.

-config %CONFIG_URL%
    The SOAtest test configuration to run.
    %CONFIG_URL% is interpreted as a URL, the name of a builtin
    configuration, or the path to a file on the server.
    Default is \"soatest.builtin://Demo Configuration\".
    Examples:
      By filename:
          -config \"mylocalconfig.properties\"
      By URL:
          -config \"http://intranet.acme.com/SOAtest/team_config.properties\"
      Builtin configurations:
          -config \"soatest.builtin://Demo Configuration\"
      User-defined configurations:
          -config \"soatest.user://Example Configuration\"

-fail
    Fail the build by returning a non-zero exit code if any violations are
    reported.

-publish
    Publishes test results to Parasoft Development Testing Platform (DTP).
    The server must already be configured to connect to Parasoft DTP.
    Default is false.

-report %REPORT_DIR_OR_FILE%
    Location where to download and locally save the XML/HTML reports.
    If a directory is specified, all available XML/HTML will be written there.
    If an .xml or .html file path is specified, then the XML/HTML report will
    be written with that file path.
    Default is the current working directory.

-resource %RESOURCE%
    Resource paths of tests to include to the test scope.
    Resource Paths are relative to the server's workspace directory.
    Use multiple times to specify multiple resources. Use quotes when the
    resource path contains spaces or other non-alphanumeric characters.
    If no resources are specified, all tests in the workspace will be executed.
    Examples:
      -resource \"/MyProject\"
      -resource \"/TestAssets/smoke_tests\"
      -resource \"/TestAssets/example.tst\"
      -resource \"/TestAssets/tutorial.tst\"

-environment %ENVIRONMENT_NAME%
    The name of the environment configuration to activate.

-debug
    Causes this script to print internal diagnostic information.
"
}

function printDebug {
    MSG="$1"
    if [ $DEBUG == true ] ; then
        echo "$MSG"
        echo ""
    fi
}

function toJsonStringArray() {
    ORIG_ARRAY=("$@")
    jsonArray=$(printf ", \"%s\"" "${ORIG_ARRAY[@]}")
    echo "[${jsonArray:2}]"
}

function dumpBase64() {
    BASE64_STR=$1
    BASE64_OUT=$2
    base64Output=$(echo "$BASE64_STR" |base64 -d > "$BASE64_OUT")
    if [ $? -ne 0 ] ; then
        echo "$base64Output"
        exit 1
    fi
}

function buildTestExecutionsRequest() {
    CONFIG=$1
    PUBLISH=$2
    RESOURCES=$3
    ENVIRONMENT=$4
    resourcesParam=""
    if [ "$RESOURCES" != "[]" ] ; then
       resourcesParam="
            \"resources\": $RESOURCES"
    fi
    soatestOptions=""
    if [ "$ENVIRONMENT" != "" ] ; then
       soatestOptions=",
    \"soatestOptions\": {
        \"environment\": \"$ENVIRONMENT\"
    }"
    fi
    echo "{
    \"general\": {
        \"config\": \"$CONFIG\",
        \"publish\": \"$PUBLISH\"
    },
    \"scopeOptions\": {
        \"workspace\": {$resourcesParam
        }
    }$soatestOptions
}"
}

DEBUG=false
SERVER=""
AUTH=""
CONFIG=""
FAIL=false
PUBLISH=false
RESOURCE=()
ENVIRONMENT=""
REPORT=""

first=0
for arg in "$@" ; do
    if [ "$first" == 0 ] ; then
        case $arg in
            -h )
                printHelp
                exit 0
                ;;
            --h )
                printHelp
                exit 0
                ;;
            -help )
                printHelp
                exit 0
                ;;
            --help )
                printHelp
                exit 0
                ;;
            -debug )
                DEBUG=true
                ;;
            -server )
                first=$arg
                ;;
            -auth )
                first=$arg
                ;;
            -config )
                first=$arg
                ;;
            -fail )
                FAIL=true
                ;;
            -publish )
                PUBLISH=true
                ;;
            -resource )
                first=$arg
                ;;
            -environment )
                first=$arg
                ;;
            -report )
                first=$arg
                ;;
            *)
                printf "unknown argument: %s\n" $arg
                printf "type \"%s -help\" for usage details\n" $COMMAND
                exit 0
                ;;
        esac
    else
        case $first in
            -server )
                SERVER=$arg
                ;;
            -auth )
                AUTH=$arg
                ;;
            -config )
                CONFIG=$arg
                ;;
            -resource )
                RESOURCE+=("$arg")
                ;;
            -environment )
                ENVIRONMENT=$arg
                ;;
            -report )
                REPORT=$arg
                ;;
            *)
                echo "unused argument: $first"
                echo "unused parameter: $arg"
                exit 3
                ;;
        esac
        first=0
    fi
done

if [ "$SERVER" == "" ] ; then
    SERVER=https://localhost:9443
    printf "Using default server: %s\n" "$SERVER"
    echo "(to use a different server, pass -server %SERVER_URL%)"
    echo ""
fi
if [ "$CONFIG" == "" ] ; then
    CONFIG="soatest.builtin://Demo Configuration"
    printf "Using default test configuration: %s\n" "$CONFIG"
    echo "(to run a different test configuration, pass -config %CONFIG_URL%)"
    echo ""
fi
if [ ${#RESOURCE[@]} -eq 0 ] ; then
    echo "All tests in the server's workspace will be executed"
    echo "(to run specific tests, pass one or more -resource %RESOURCE%)"
    echo ""
fi
if [ "$REPORT" == "" ] ; then
    REPORT="."
    echo "Reports will be written to the current working directory"
    echo "(to specify a different location, pass -report %REPORT_DIR_OR_FILE%)"
    echo ""
fi

COMMON_CURL_ARGS=(-s -S -f -k -H "Accept: application/json" --connect-timeout 30)
COMMON_CURL_ARGS_NO_FAIL=(-s -S -k -H "Accept: application/json" --connect-timeout 30)
if [ "$AUTH" != "" ] ; then
    COMMON_CURL_ARGS+=("-u")
    COMMON_CURL_ARGS+=("$AUTH")
    COMMON_CURL_ARGS_NO_FAIL+=("-u")
    COMMON_CURL_ARGS_NO_FAIL+=("$AUTH")
fi

echo "Checking server status: $SERVER"
getStatusResponse=$(curl \
    "${COMMON_CURL_ARGS[@]}" \
    $SERVER/soavirt/api/v5/status)
if [ $? -ne 0 ] ; then
    printDebug "$getStatusResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        $SERVER/soavirt/api/v5/status
    echo ""
    exit 1
fi
printDebug "$getStatusResponse"
if [ "${getStatusResponse:0:1}" != '{' ] ; then
    echo "Status check failed!  Received non-JSON response.  Please verify the server URL is correct."
    exit 1
fi

testExecutionsRequest=$(buildTestExecutionsRequest "$CONFIG" "$PUBLISH" "$(toJsonStringArray "${RESOURCE[@]}")" "$ENVIRONMENT")
printDebug "$testExecutionsRequest"
testExecutionsResponse=$(curl \
    "${COMMON_CURL_ARGS[@]}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "${testExecutionsRequest}" \
    $SERVER/soavirt/api/v5/testExecutions)
if [ $? -ne 0 ] ; then
    printDebug "$testExecutionsResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "${testExecutionsRequest}" \
        $SERVER/soavirt/api/v5/testExecutions
    echo ""
    exit 1
fi
printDebug "$testExecutionsResponse"
jobId=$(echo "$testExecutionsResponse" |sed -e 's/\s*{\s*"id"\s*:\s*"\([^"]\+\)"\s*}\s*/\1/g')
printf "Test execution submitted with job ID %s\n" $jobId

testExecutionNotDone=true
percent="-1"
while [ $testExecutionNotDone == true ] ; do
    testExecutionsStatusResponse=$(curl \
        "${COMMON_CURL_ARGS[@]}" \
        "$SERVER/soavirt/api/v5/testExecutions/${jobId}/status")
    if [ $? -ne 0 ] ; then
        printDebug "$testExecutionsStatusResponse"
        curl \
            "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
            "$SERVER/soavirt/api/v5/testExecutions/${jobId}/status"
        echo ""
        exit 1
    fi
    printDebug "$testExecutionsStatusResponse"
    oldPercent=$percent
    isRunning=$(echo $testExecutionsStatusResponse |sed -e 's/.\+"isRunning"\s*:\s*\(true\|false\).*/\1/g')
    percent=$(echo $testExecutionsStatusResponse |sed -e 's/.\+"percent"\s*:\s*\([^,}\s]\+\).*/\1/g')
    if [ "$oldPercent" != "$percent" ] ; then
        if [ $percent -eq 0 ] && [ $isRunning == false ] ; then
            echo "Job is queued and will run after other jobs on the server have completed"
            echo "(please wait)"
        else
            if [ $oldPercent -lt 1 ] && [ $percent -gt 0 ] ; then
               echo "Job started"
            fi
            printf "%s%%\n" $percent
        fi
    fi
    if [ $isRunning == false ] && [ $percent -eq 100 ] ; then
        testExecutionNotDone=false
    fi
    sleep .5
done

echo "Retrieving test results"
testExecutionsResultsResponse=$(curl \
    "${COMMON_CURL_ARGS[@]}" \
    "$SERVER/soavirt/api/v5/testExecutions/${jobId}/results?includeReportArchive=true&includeHtmlReport=true&includeXmlReport=true")
if [ $? -ne 0 ] ; then
    printDebug "$testExecutionsResultsResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        "$SERVER/soavirt/api/v5/testExecutions/${jobId}/results?includeReportArchive=true&includeHtmlReport=true&includeXmlReport=true"
    echo ""
    exit 1
fi
printDebug "$testExecutionsResultsResponse"

failureCount=0
testRunCount=0
if [[ "$testExecutionsResultsResponse" == *"failureCount"* ]] ; then
    failureCount=$(echo $testExecutionsResultsResponse |sed -e 's/.\+"failureCount"\s*:\s*\([^,}\s]\+\).*/\1/g')
fi
if [[ "$testExecutionsResultsResponse" == *"testRunCount"* ]] ; then
    testRunCount=$(echo $testExecutionsResultsResponse |sed -e 's/.\+"testRunCount"\s*:\s*\([^,}\s]\+\).*/\1/g')
fi
printf "Test results summary (failures/total): %s/%s\n" "$failureCount" "$testRunCount"

reportIsDir=true
reportIsXmlFile=false
reportIsHtmlFile=false
if [[ "$REPORT" == *".xml" ]] || [[ "$REPORT" == *".XML" ]] ; then
    reportIsXmlFile=true
    reportIsDir=false
elif [[ "$REPORT" == *".html" ]] || [[ "$REPORT" == *".HTML" ]] ; then
    reportIsHtmlFile=true
    reportIsDir=false
fi

if [ $reportIsDir == true ] ; then
    mkdirOutput=$(mkdir -p "$REPORT")
    if [ $? -ne 0 ] ; then
        echo "$mkdirOutput"
        exit 1
    fi
    printDebug "$mkdirOutput"
else
    mkdirOutput=$(mkdir -p "$(dirname "$REPORT")")
    if [ $? -ne 0 ] ; then
        echo "$mkdirOutput"
        exit 1
    fi
    printDebug "$mkdirOutput"
fi

reportArchive=""
if [ $reportIsDir == true ] && [[ "$testExecutionsResultsResponse" == *"reportArchive"* ]] ; then
    reportArchive=$(echo $testExecutionsResultsResponse |sed -e 's/.\+"reportArchive"\s*:\s*"\([^"]*\)".*/\1/g')
fi
if [ "$reportArchive" != "" ] ; then
    printf "Extracting report archive to %s\n" "$REPORT"
    dumpBase64 "$reportArchive" "$REPORT/archive.zip"
    printDebug "$base64Output"
    unzipOutput=$(unzip -o "$REPORT/archive.zip" -d "$REPORT")
    if [ $? -ne 0 ] ; then
        echo "$unzipOutput"
        exit 1
    fi
    printDebug "$unzipOutput"
else
    if [[ "$testExecutionsResultsResponse" == *"xmlReport"* ]] ; then
        xmlReport=$(echo $testExecutionsResultsResponse |sed -e 's/.\+"xmlReport"\s*:\s*"\([^"]*\)".*/\1/g')
        if [ "$xmlReport" != "" ] ; then
            if [ $reportIsXmlFile == true ] ; then
                printf "Extracting XML report as %s\n" "$REPORT"
                dumpBase64 "$xmlReport" "$REPORT"
            elif [ $reportIsHtmlFile == true ] ; then
                htmlBaseDir=$(dirname "$REPORT")
                htmlBaseName=$(basename "$REPORT")
                htmlBaseName="${htmlBaseName%.*}"
                printf "Extracting XML report as %s\n" "${htmlBaseDir}/${htmlBaseName}.xml"
                dumpBase64 "$xmlReport" "${htmlBaseDir}/${htmlBaseName}.xml"
            else
                printf "Extracting XML report as %s\n" "$REPORT/report.xml"
                dumpBase64 "$xmlReport" "$REPORT/report.xml"
            fi
        fi
    fi
    if [[ "$testExecutionsResultsResponse" == *"htmlReport"* ]] ; then
        htmlReport=$(echo $testExecutionsResultsResponse |sed -e 's/.\+"htmlReport"\s*:\s*"\([^"]*\)".*/\1/g')
        if [ "$htmlReport" != "" ] ; then
            if [ $reportIsHtmlFile == true ] ; then
                printf "Extracting HTML report as %s\n" "$REPORT"
                dumpBase64 "$htmlReport" "$REPORT"
            elif [ $reportIsXmlFile == true ] ; then
                xmlBaseDir=$(dirname "$REPORT")
                xmlBaseName=$(basename "$REPORT")
                xmlBaseName="${xmlBaseName%.*}"
                printf "Extracting HTML report as %s\n" "${xmlBaseDir}/${xmlBaseName}.html"
                dumpBase64 "$htmlReport" "${xmlBaseDir}/${xmlBaseName}.html"
            else
                printf "Extracting HTML report as %s\n" "$REPORT/report.html"
                dumpBase64 "$htmlReport" "$REPORT/report.html"
            fi
        fi
    fi
fi

if [ $FAIL == true ] && [ $failureCount -gt 0 ] ; then
    exit 4
else
    echo "Success!"
fi

echo ""
