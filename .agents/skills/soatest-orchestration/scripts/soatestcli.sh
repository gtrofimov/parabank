#!/usr/bin/env bash

COMMAND=$(basename "$0")
printf "%s: -- Copyright (C) 2025 Parasoft Corporation\n\n" $COMMAND

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
    Default is \"soatest.builtin://Run Automated Server Tests\".
    Examples:
      By filename:
          -config \"mylocalconfig.properties\"
      By URL:
          -config \"http://intranet.acme.com/SOAtest/team_config.properties\"
      Builtin configurations:
          -config \"soatest.builtin://Run Automated Server Tests\"
      User-defined configurations:
          -config \"soatest.user://Example Configuration\"

-fail
    Fail the build by returning a non-zero exit code if any violations are
    reported.

-parallel
    Execute .tst files in parallel.

-property %KEY%=%VALUE%
     Sets custom configuration entry.
     This option can be specified multiple times.

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

-include %PATTERN%
-exclude %PATTERN%
    Specifies resources to be included/excluded during testing.
    Syntax for the patterns is similar to that of Ant filesets.
    Patterns specify packages, with the wildcards * and ? accepted, and the
    special wildcard ** used to specify one or more package name segments.

-workItems %ID_LIST%
    Specifies a comma-delimited list of work item ids. Its presence will
    limit the test scope to the resources that are associated with those
    work items.

-dataGroupConfig %DATA_GROUP_CONFIG_FILE%
    Specifies the active data source within a data group.
    This argument must be followed by the location of a JSON file that
    specifies the active data source for each data group within each .tst file
    contained in the test run.

-dataSourceRow  %LIST_OF_NUMBERS_OR_RANGES%
-dataSourceName %DATA_SOURCE_NAME%
    Runs all tests with the specified data source rows(s).
    You can specify a list of row numbers or row ranges.
    You can also specify \"all\" as the value to force all data source rows to
    be used, even if the data sources were saved to use only specific rows.
    You can use the -dataSourceName option to specify which data source
    contains the row associated with the tests you want to execute.
    The -dataSourceName argument is optional.

-environment %ENVIRONMENT_NAME%
    The name of the environment configuration to activate.

-environmentConfig %ENVIRONMENT_CONFIG_FILE%
    Specifies the active environment variables.
    This argument must be followed by the location of a JSON file that
    specifies the environment variable values to use for each .tst file
    contained in the test run.

-debug
    Causes this script to print internal diagnostic information.
"
}

function printDebug {
    local msg="$1"
    if [ $DEBUG == true ] ; then
        echo "$msg"
        echo ""
    fi
}

function toJsonStringArray() {
    local array=("$@")
    local json=""
    for item in "${array[@]}"; do
        json+=", \"${item}\""
    done
    echo "[${json:2}]"
}

function toJsonNameValueArray() {
    local array=("$@")
    local json=""
    for item in "${array[@]}"; do
        name="${item%%=*}"
        value="${item#*=}"
        json="${json}, {\"name\": \"${name}\", \"value\": \"${value}\"}"
    done
    echo "[${json:2}]"
}

function toJsonObject() {
    local indentLevel="$1"
    local -n names="$2"
    local -n values="$3"
    local singleIndent="  "
    local indent=""
    for ((i=0; i<indentLevel; i++)); do
        indent+="${singleIndent}"
    done
    local output=""
    if [ ${#names[@]} -gt 0 ] ; then
        local params=""
        for ((i=0; i<${#names[@]}; i++)); do
            params+=','
            params+=$'\n'
            params+="${indent}"
            params+="${singleIndent}\"${names[i]}\": ${values[i]}"
        done
        output="{"
        output+=$'\n'
        output+="${params:2}"
        output+=$'\n'
        output+="${indent}}"
    fi
    echo "$output"
}

function dumpBase64() {
    local base64Str=$1
    local base64Out=$2
    local base64Output=$(echo "$base64Str" |base64 -d > "$base64Out")
    if [ $? -ne 0 ] ; then
        echo "$base64Output"
        exit 1
    fi
}

function buildTestExecutionsRequest() {
    local config=$1
    local properties=$2
    local parallel=$3
    local publish=$4
    local excludes=$5
    local includes=$6
    local resources=$7
    local workItems=$8
    local dataGroupConfig=$9
    local dataSourceRow=${10}
    local dataSourceName=${11}
    local environment=${12}
    local environmentConfig=${13}

    local generalNames=()
    local generalValues=()
    generalNames+=("config")
    generalValues+=("\"${config}\"")
    if [ "$properties" != "[]" ] ; then
        generalNames+=("localSettings")
        generalValues+=("${properties}")
    fi
    generalNames+=("parallel")
    generalValues+=("${parallel}")
    generalNames+=("publish")
    generalValues+=("${publish}")
    local generalObject=$(toJsonObject \
        1 \
        generalNames \
        generalValues \
    )

    local workspaceNames=()
    local workspaceValues=()
    if [ "$excludes" != "[]" ] ; then
        workspaceNames+=("excludes")
        workspaceValues+=("${excludes}")
    fi
    if [ "$includes" != "[]" ] ; then
        workspaceNames+=("includes")
        workspaceValues+=("${includes}")
    fi
    if [ "$resources" != "[]" ] ; then
        workspaceNames+=("resources")
        workspaceValues+=("${resources}")
    fi
    if [ "$workItems" != "[]" ] ; then
        workspaceNames+=("workItems")
        workspaceValues+=("${workItems}")
    fi
    local workspaceObject=$(toJsonObject \
        2 \
        workspaceNames \
        workspaceValues \
    )

    local scopeOptionsNames=()
    local scopeOptionsValues=()
    if [ -n "${workspaceObject}" ] ; then
        scopeOptionsNames+=("workspace")
        scopeOptionsValues+=("${workspaceObject}")
    fi
    local scopeOptionsObject=$(toJsonObject \
        1 \
        scopeOptionsNames \
        scopeOptionsValues \
    )

    local dataSourceNames=()
    local dataSourceValues=()
    if [ -n "${dataSourceName}" ] ; then
        dataSourceNames+=("dataSourceName")
        dataSourceValues+=("\"${dataSourceName}\"")
    fi
    if [ -n "${dataSourceRow}" ] ; then
        dataSourceNames+=("dataSourceRow")
        dataSourceValues+=("\"${dataSourceRow}\"")
    fi
    local dataSourceObject=$(toJsonObject \
        2 \
        dataSourceNames \
        dataSourceValues \
    )

    local soatestOptionsNames=()
    local soatestOptionsValues=()
    if [ -n "${dataGroupConfig}" ] ; then
        soatestOptionsNames+=("dataGroupConfig")
        soatestOptionsValues+=("${dataGroupConfig}")
    fi
    if [ -n "${dataSourceObject}" ] ; then
        soatestOptionsNames+=("dataSource")
        soatestOptionsValues+=("${dataSourceObject}")
    fi
    if [ -n "${environment}" ] ; then
        soatestOptionsNames+=("environment")
        soatestOptionsValues+=("\"${environment}\"")
    fi
    if [ -n "${environmentConfig}" ] ; then
        soatestOptionsNames+=("environmentConfig")
        soatestOptionsValues+=("${environmentConfig}")
    fi
    local soatestOptionsObject=$(toJsonObject \
        1 \
        soatestOptionsNames \
        soatestOptionsValues \
    )

    local rootNames=()
    local rootValues=()
    if [ -n "${generalObject}" ] ; then
        rootNames+=("general")
        rootValues+=("${generalObject}")
    fi
    if [ -n "${scopeOptionsObject}" ] ; then
        rootNames+=("scopeOptions")
        rootValues+=("${scopeOptionsObject}")
    fi
    if [ -n "${soatestOptionsObject}" ] ; then
        rootNames+=("soatestOptions")
        rootValues+=("${soatestOptionsObject}")
    fi
    local rootObject=$(toJsonObject \
        0 \
        rootNames \
        rootValues \
    )
    echo "${rootObject}"
}

DEBUG=false
SERVER=""
BASE_PATH='/soavirt/api/v6'
AUTH=""
CONFIG=""
FAIL=false
PARALLEL=false
PROPERTY=()
PUBLISH=false
RESOURCE=()
INCLUDE=()
EXCLUDE=()
WORK_ITEMS=()
DATA_GROUP_CONFIG=""
DATA_SOURCE_ROW=""
DATA_SOURCE_NAME=""
ENVIRONMENT=""
ENVIRONMENT_CONFIG=""
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
                first="$arg"
                ;;
            -auth )
                first="$arg"
                ;;
            -config )
                first="$arg"
                ;;
            -fail )
                FAIL=true
                ;;
            -parallel )
                PARALLEL=true
                ;;
            -property )
                first="$arg"
                ;;
            -publish )
                PUBLISH=true
                ;;
            -resource )
                first="$arg"
                ;;
            -include )
                first="$arg"
                ;;
            -exclude )
                first="$arg"
                ;;
            -workItems )
                first="$arg"
                ;;
            -dataGroupConfig )
                first="$arg"
                ;;
            -dataSourceRow )
                first="$arg"
                ;;
            -dataSourceName )
                first="$arg"
                ;;
            -environment )
                first="$arg"
                ;;
            -environmentConfig )
                first="$arg"
                ;;
            -report )
                first="$arg"
                ;;
            *)
                printf "unknown argument: %s\n" $arg
                printf "type \"%s -help\" for usage details\n" $COMMAND
                exit 1
                ;;
        esac
    else
        case $first in
            -server )
                SERVER="$arg"
                ;;
            -auth )
                AUTH="$arg"
                ;;
            -config )
                CONFIG="$arg"
                ;;
            -property )
                PROPERTY+=("$arg")
                ;;
            -resource )
                RESOURCE+=("$arg")
                ;;
            -include )
                INCLUDE+=("$arg")
                ;;
            -exclude )
                EXCLUDE+=("$arg")
                ;;
            -workItems )
                IFS=',' read -ra WORK_ITEMS <<< "$arg"
                ;;
            -dataGroupConfig )
                if [ ! -f "$arg" ]; then
                    echo "Data group configuration file does not exist: ${arg}"
                    exit 1
                fi
                if [ ! -r "$arg" ]; then
                    echo "Data group configuration file is not readable: ${arg}"
                    exit 1
                fi
                DATA_GROUP_CONFIG=$(<"$arg")
                ;;
            -dataSourceRow )
                DATA_SOURCE_ROW="$arg"
                ;;
            -dataSourceName )
                DATA_SOURCE_NAME="$arg"
                ;;
            -environment )
                ENVIRONMENT="$arg"
                ;;
            -environmentConfig )
                if [ ! -f "$arg" ]; then
                    echo "Environment configuration file does not exist: ${arg}"
                    exit 1
                fi
                if [ ! -r "$arg" ]; then
                    echo "Environment configuration file is not readable: ${arg}"
                    exit 1
                fi
                ENVIRONMENT_CONFIG=$(<"$arg")
                ;;
            -report )
                REPORT="$arg"
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

if [ -z "$SERVER" ] ; then
    SERVER=https://localhost:9443
    printf "Using default server: %s\n" "$SERVER"
    echo "(to use a different server, pass -server %SERVER_URL%)"
    echo ""
fi
if [ -z "$CONFIG" ] ; then
    CONFIG="soatest.builtin://Run Automated Server Tests"
    printf "Using default test configuration: %s\n" "$CONFIG"
    echo "(to run a different test configuration, pass -config %CONFIG_URL%)"
    echo ""
fi
if [ ${#RESOURCE[@]} -eq 0 ] ; then
    echo "All tests in the server's workspace will be executed"
    echo "(to run specific tests, pass one or more -resource %RESOURCE%)"
    echo ""
    # at least one resource is required
    # empty string will run all tests in the workspace
    RESOURCE+=("")
fi
if [ -z "$REPORT" ] ; then
    REPORT="."
    echo "Reports will be written to the current working directory"
    echo "(to specify a different location, pass -report %REPORT_DIR_OR_FILE%)"
    echo ""
fi

COMMON_CURL_ARGS=(-s -S -f -k -H "Accept: application/json" --connect-timeout 30)
COMMON_CURL_ARGS_NO_FAIL=(-s -S -k -H "Accept: application/json" --connect-timeout 30)
if [ -n "$AUTH" ] ; then
    COMMON_CURL_ARGS+=("-u")
    COMMON_CURL_ARGS+=("$AUTH")
    COMMON_CURL_ARGS_NO_FAIL+=("-u")
    COMMON_CURL_ARGS_NO_FAIL+=("$AUTH")
fi

echo "Checking server status: $SERVER"
getStatusResponse=$(curl \
    "${COMMON_CURL_ARGS[@]}" \
    ${SERVER}${BASE_PATH}/status)
if [ $? -ne 0 ] ; then
    printDebug "$getStatusResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        ${SERVER}${BASE_PATH}/status
    echo ""
    exit 1
fi
printDebug "$getStatusResponse"
if [ "${getStatusResponse:0:1}" != '{' ] ; then
    echo "Status check failed!  Received non-JSON response.  Please verify the server URL is correct."
    exit 1
fi

testExecutionsRequest=$(buildTestExecutionsRequest \
        "$CONFIG" \
        "$(toJsonNameValueArray "${PROPERTY[@]}")" \
        "$PARALLEL" \
        "$PUBLISH" \
        "$(toJsonStringArray "${EXCLUDE[@]}")" \
        "$(toJsonStringArray "${INCLUDE[@]}")" \
        "$(toJsonStringArray "${RESOURCE[@]}")" \
        "$(toJsonStringArray "${WORK_ITEMS[@]}")" \
        "$DATA_GROUP_CONFIG" \
        "$DATA_SOURCE_ROW" \
        "$DATA_SOURCE_NAME" \
        "$ENVIRONMENT" \
        "$ENVIRONMENT_CONFIG")
printDebug "$testExecutionsRequest"
testExecutionsResponse=$(curl \
    "${COMMON_CURL_ARGS[@]}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "${testExecutionsRequest}" \
    ${SERVER}${BASE_PATH}/testExecutions)
if [ $? -ne 0 ] ; then
    printDebug "$testExecutionsResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "${testExecutionsRequest}" \
        ${SERVER}${BASE_PATH}/testExecutions
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
        "${SERVER}${BASE_PATH}/testExecutions/${jobId}/status")
    if [ $? -ne 0 ] ; then
        printDebug "$testExecutionsStatusResponse"
        curl \
            "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
            "${SERVER}${BASE_PATH}/testExecutions/${jobId}/status"
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
    "${SERVER}${BASE_PATH}/testExecutions/${jobId}/results?includeReportArchive=true&includeHtmlReport=true&includeXmlReport=true")
if [ $? -ne 0 ] ; then
    printDebug "$testExecutionsResultsResponse"
    curl \
        "${COMMON_CURL_ARGS_NO_FAIL[@]}" \
        "${SERVER}${BASE_PATH}/testExecutions/${jobId}/results?includeReportArchive=true&includeHtmlReport=true&includeXmlReport=true"
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
if [ -n "$reportArchive" ] ; then
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
        if [ -n "$xmlReport" ] ; then
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
        if [ -n "$htmlReport" ] ; then
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
