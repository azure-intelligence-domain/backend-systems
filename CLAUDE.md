# CLAUDE.md

The simulated source systems (ADR 0007). Ground rules live in the
[ai-intelligence-domain](https://github.com/azure-intelligence-domain/ai-intelligence-domain)
repository.

- Each system keeps its own data model with that system's own naming (Salesforce: PascalCase and
  `__c` custom fields). Never shape it after the platform's contracts: that is the System API's job.
- Entra ID only (`disableLocalAuth`); only the system's System API runtime identity gets a data role.
- Serverless / pay-per-use only.
