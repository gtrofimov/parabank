# Compile the source and run tests
```
mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```
# Run UT
```
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests"
```
# Run TIA
```
mvn tia:affected-tests test -Djtest.referenceCoverageFile=target/jtest/baseline/coverage.xml -Djtest.referenceReportFile=target/jtest/baseline/report.xml -Djtest.runFailedTests=false -Djtest.runModifiedTests=true
```

# Run SA
```
jtestcli -data target/jtest/jtest.data.json -config "builtin://builtin://CWE Top 25 + On the Cusp 2025"
```