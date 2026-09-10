# Baseline

mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true

## SA

jtestcli 


.agents/skills/soatest-orchestration/scripts/soatestcli.sh \
  -server "$SOATEST_SERVER" \
  -config "$SOATEST_CONFIG" \
  -report reports/soatest/loan-history-manual \
  -resource /TestAssets/generated_by_mcp/Loan_Request_History_API.tst \
  -property build.id=Parabank-Jenkins-project-test \
  -property dtp.enabled=true \
  -property dtp.url=${DTP_URL} \
  -property dtp.user=${DTP_USER} \
  -property dtp.password=${DTP_PASSWORD} \
  -property dtp.project=${DTP_PROJECT} \
  -property session.tag=soatest \
  -property report.dtp.publish=true \
  -property report.associations=true \
  -property application.coverage.enabled=true \
  -property application.coverage.agent.url="http://localhost:8051;http://localhost:8052" \
  -property application.coverage.dtp.publish=true \
  -property application.coverage.images=${DTP_SOATEST_COVERAGE_IMAGES}

-property application.coverage.enabled=true \
-property application.coverage.agent.url=http://localhost:8050 \
-property dtp.project=Parabank-Jenkins \
-property build.id=Parabank-Jenkins-feature-central-20260907190529 \
-property dtp.enabled=true \
-property dtp.url=${DTP_URL} \
-property dtp.user=${DTP_USER} \
-property dtp.password=${DTP_PASSWORD} \
-property dtp.project=${DTP_PROJECT} \
-property session.tag=soatest \
-property report.dtp.publish=true \
-property report.associations=true \
-property report.scontrol=full \
-property scope.local=true \
-property scope.scontrol=true \
-property scope.xmlmap=false \
-property application.coverage.enabled=true \
-property application.coverage.agent.url=http://localhost:8050 \
-property application.coverage.dtp.publish=true \
-property application.coverage.images=${DTP_SOATEST_COVERAGE_IMAGES}