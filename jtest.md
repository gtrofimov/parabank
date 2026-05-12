# Compile the source and run tests
```
mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```
# Run UT
```
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests"
```

# Run SA
```
jtestcli -data target/jtest/jtest.data.json -config "builtin://builtin://CWE Top 25 + On the Cusp 2025"
```