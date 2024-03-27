# Create Daily Report (CDR) Script Documentation

## Synopsis
The `cdr.ps1` PowerShell script processes JSON data from a specified file path and generates reports for organizations and parties at the specified report location.

## Usage

## Parameters
- `-JsonFilePath <string>`: Specifies the file path to the JSON data, which should typically be the response from an API call to a bank.
- `-ReportPath <string>`: Specifies the location where reports for organizations and parties will be generated.

## Assumptions

1. The system is designed to work as follows:
  - The bank has a service through which data can be read in JSON format that adheres to the JSON schema provided in the text below.
  - The data is fetched and saved into a JSON file.
  - That file is then passed as an argument to the script.
2. The script assumes the existence of a `TEMP` environment variable that points to a temporary location on the system. In this location, a working directory is created to store temporary files needed during script execution.

## Logs
All actions executed are logged in a file named `cdr_yyyy-MM-dd_HH-mm-ss.log`, which makes daily log monitoring easier.

## Example
```powershell
pwsh -File cdr.ps1 -JsonFilePath data.json -ReportPath "./izvodi"
```

## JSON Schema Requirement
The script expects input data that adheres to the following JSON schema:

```json
{
  "title": "Generated schema",
  "type": "object",
  "properties": {
    "date": {
      "type": "string"
    },
    "organizations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string"
          },
          "parties": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "string"
                },
                "lastActivity": {
                  "type": "string"
                },
                "type": {
                  "type": "string"
                },
                "organizationId": {
                  "type": "string"
                }
              },
              "required": [
                "id",
                "lastActivity",
                "type",
                "organizationId"
              ]
            }
          }
        },
        "required": [
          "id",
          "parties"
        ]
      }
    }
  },
  "required": [
    "date",
    "organizations"
  ]
}
```

# Data Mocking Tool (DMT) Documentation

## Synopsis
The `dmt.ps1` PowerShell script generates mock data for organizations and parties.

## Usage

## Parameters
- `-numberOfOrganizations <int>`: Specifies the total number of organizations to be generated.
- `-numberOfParties <int>`: Specifies the total number of parties to be generated. Parties will be distributed randomly among organizations.
- `-date <string>`: Specifies the date for which data should be retrieved.
- `-numberOfActiveParties <int>`: Specifies the number of active parties for the requested date. A party is active if the date and last activity of the party are the same day.
- `-numberOfExternalParties <int>`: Specifies the number of parties to be distributed. For the distribution of external parties to be possible, the number of organizations must be greater than 1. Value should be in the range from 0 to numberOfParties. Parties will be distributed randomly among organizations.

## Output
The output of the script is written to the default output and can be piped into a file using the `-FilePath` parameter of the `Out-File` cmdlet.

## Example
```powershell
pwsh -File dmt.ps1 -numberOfOrganizations 8 -numberOfParties 10 -date "2024-02-02" -numberOfActiveParties 5 -numberOfExternalParties 4 | Out-File -FilePath test.json
```
