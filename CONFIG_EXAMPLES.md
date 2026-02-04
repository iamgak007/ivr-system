# IVR Configuration Examples

This document provides ready-to-use configuration examples for common IVR scenarios.

---

## Table of Contents

1. [Simple Welcome Flow](#simple-welcome-flow)
2. [Multi-Level Menu](#multi-level-menu)
3. [Language Selection](#language-selection)
4. [Collect Customer ID](#collect-customer-id)
5. [Record Message](#record-message)
6. [API Authentication](#api-authentication)
7. [Create Incident with Recording](#create-incident-with-recording)
8. [Transfer to Agent](#transfer-to-agent)
9. [Business Hours Check](#business-hours-check)
10. [Dynamic Text-to-Speech](#dynamic-text-to-speech)
11. [Conditional Routing](#conditional-routing)
12. [Complete Customer Service Flow](#complete-customer-service-flow)

---

## Simple Welcome Flow

**Scenario**: Play welcome message and go to main menu.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1000,
      "NodeName": "Welcome Message",
      "OperationCode": 10,
      "VoiceFileId": "welcome.wav",
      "IsStartNode": true,
      "ChildNodeConfig": [
        {"ChildNodeId": 1001}
      ],
      "RepeatLimit": 0
    },
    {
      "NodeId": 1001,
      "NodeName": "Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "main_menu.wav",
      "ValidKeys": "1,2,3,0",
      "InputTimeLimit": 10,
      "TagName": "MainMenuSelection",
      "ChildNodeConfig": [
        {"ChildNodeId": 2000, "InputKeys": "1"},
        {"ChildNodeId": 3000, "InputKeys": "2"},
        {"ChildNodeId": 4000, "InputKeys": "3"},
        {"ChildNodeId": 5000, "InputKeys": "0"},
        {"ChildNodeId": 1002, "InputKeys": "X"},
        {"ChildNodeId": 1002, "InputKeys": "T"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid_option.wav"
    },
    {
      "NodeId": 1002,
      "NodeName": "Too Many Attempts",
      "OperationCode": 10,
      "VoiceFileId": "goodbye.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 9999,
      "NodeName": "End Call",
      "OperationCode": 200
    }
  ]
}
```

**Audio Files Needed**:
- `welcome.wav`: "Welcome to our service."
- `main_menu.wav`: "Press 1 for sales, 2 for support, 3 for billing, or 0 for operator."
- `invalid_option.wav`: "Invalid selection. Please try again."
- `goodbye.wav`: "Goodbye."

---

## Multi-Level Menu

**Scenario**: Main menu with sub-menus.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1000,
      "NodeName": "Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "main_menu.wav",
      "IsStartNode": true,
      "ValidKeys": "1,2",
      "InputTimeLimit": 10,
      "TagName": "MainChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 1100, "InputKeys": "1"},
        {"ChildNodeId": 1200, "InputKeys": "2"},
        {"ChildNodeId": 1000, "InputKeys": "X"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav",
      "IsRepetitive": true
    },
    {
      "NodeId": 1100,
      "NodeName": "Sales Sub-Menu",
      "OperationCode": 30,
      "VoiceFileId": "sales_menu.wav",
      "ValidKeys": "1,2,9",
      "InputTimeLimit": 10,
      "TagName": "SalesChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 1110, "InputKeys": "1"},
        {"ChildNodeId": 1120, "InputKeys": "2"},
        {"ChildNodeId": 1000, "InputKeys": "9"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav",
      "IsRepetitive": true
    },
    {
      "NodeId": 1110,
      "NodeName": "New Customers",
      "OperationCode": 10,
      "VoiceFileId": "new_customers.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 1120,
      "NodeName": "Existing Customers",
      "OperationCode": 10,
      "VoiceFileId": "existing_customers.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 1200,
      "NodeName": "Support Sub-Menu",
      "OperationCode": 30,
      "VoiceFileId": "support_menu.wav",
      "ValidKeys": "1,2,9",
      "InputTimeLimit": 10,
      "TagName": "SupportChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 1210, "InputKeys": "1"},
        {"ChildNodeId": 1220, "InputKeys": "2"},
        {"ChildNodeId": 1000, "InputKeys": "9"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav",
      "IsRepetitive": true
    },
    {
      "NodeId": 9999,
      "NodeName": "End Call",
      "OperationCode": 200
    }
  ]
}
```

**Audio Files**:
- `main_menu.wav`: "Press 1 for sales, 2 for support"
- `sales_menu.wav`: "Press 1 for new customers, 2 for existing customers, 9 to return"
- `support_menu.wav`: "Press 1 for technical support, 2 for billing, 9 to return"

---

## Language Selection

**Scenario**: Let caller choose language before proceeding.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1000,
      "NodeName": "Language Selection",
      "OperationCode": 30,
      "VoiceFileId": "language_prompt.wav",
      "IsStartNode": true,
      "ValidKeys": "1,2",
      "InputTimeLimit": 10,
      "InputLength": 1,
      "TagName": "LanguageSelected",
      "IsLanguageSelect": true,
      "ChildNodeConfig": [
        {"ChildNodeId": 1100, "InputKeys": "1"},
        {"ChildNodeId": 1200, "InputKeys": "2"},
        {"ChildNodeId": 1001, "InputKeys": "X"},
        {"ChildNodeId": 1001, "InputKeys": "T"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid_language.wav",
      "DeafultInput": "1",
      "IsRepetitive": true
    },
    {
      "NodeId": 1001,
      "NodeName": "Default to English",
      "OperationCode": 10,
      "VoiceFileId": "defaulting_english.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 1100}
      ]
    },
    {
      "NodeId": 1100,
      "NodeName": "English Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "main_menu_en.wav",
      "ValidKeys": "1,2,3",
      "InputTimeLimit": 10,
      "TagName": "MenuChoice_EN",
      "ChildNodeConfig": [
        {"ChildNodeId": 2000, "InputKeys": "1"},
        {"ChildNodeId": 3000, "InputKeys": "2"},
        {"ChildNodeId": 4000, "InputKeys": "3"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid_en.wav"
    },
    {
      "NodeId": 1200,
      "NodeName": "Arabic Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "main_menu_ar.wav",
      "ValidKeys": "1,2,3",
      "InputTimeLimit": 10,
      "TagName": "MenuChoice_AR",
      "ChildNodeConfig": [
        {"ChildNodeId": 2100, "InputKeys": "1"},
        {"ChildNodeId": 3100, "InputKeys": "2"},
        {"ChildNodeId": 4100, "InputKeys": "3"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid_ar.wav"
    }
  ]
}
```

### GeneralSettingValues
```json
{
  "SettingId": 15,
  "SettingnKey": "LanguageList",
  "SettingValue": "[{\"LanguageCode\":1,\"LanguageName\":\"Arabic\",\"TTSLanguageCode\":\"ar-SA\",\"STTLanguageCode\":\"ar-SA\",\"TTSVoiceNameCloud\":\"ar-SA-ZariyahNeural\"},{\"LanguageCode\":2,\"LanguageName\":\"English\",\"TTSLanguageCode\":\"en-US\",\"STTLanguageCode\":\"en-US\",\"TTSVoiceNameCloud\":\"en-US-GuyNeural\"}]"
}
```

---

## Collect Customer ID

**Scenario**: Collect multi-digit customer ID.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 3000,
      "NodeName": "Request Customer ID",
      "OperationCode": 30,
      "VoiceFileId": "enter_customer_id.wav",
      "ValidKeys": "0,1,2,3,4,5,6,7,8,9,#",
      "InputType": 20,
      "InputLength": 10,
      "InputTimeLimit": 30,
      "TagName": "CustomerID",
      "ChildNodeConfig": [
        {"ChildNodeId": 3001, "InputKeys": "*"},
        {"ChildNodeId": 3002, "InputKeys": "X"},
        {"ChildNodeId": 3002, "InputKeys": "T"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid_customer_id.wav"
    },
    {
      "NodeId": 3001,
      "NodeName": "Validate Customer ID",
      "OperationCode": 111,
      "APIId": 15,
      "ChildNodeConfig": [
        {"ChildNodeId": 3010, "InputKeys": "S"},
        {"ChildNodeId": 3020, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 3010,
      "NodeName": "Valid Customer",
      "OperationCode": 330,
      "APIId": 19,
      "DeafultInput": "Welcome {{CustomerName}}. Your account is active.",
      "ChildNodeConfig": [
        {"ChildNodeId": 4000}
      ]
    },
    {
      "NodeId": 3020,
      "NodeName": "Invalid Customer",
      "OperationCode": 10,
      "VoiceFileId": "customer_not_found.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 3000}
      ]
    },
    {
      "NodeId": 3002,
      "NodeName": "Too Many Attempts",
      "OperationCode": 10,
      "VoiceFileId": "transfer_to_agent.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 5000}
      ]
    }
  ]
}
```

### automax_webAPIConfig.json
```json
{
  "apiId": 15,
  "apiDescription": "Validate Customer ID",
  "serviceURL": "https://api.example.com/customers/validate",
  "methodType": "POST",
  "securityMode": "A",
  "inputMediaType": "application/json",
  "apiInput": {
    "values": [
      {
        "name": "Authorization",
        "value": "Bearer {{Access_token}}",
        "InputType": "H",
        "InputValueType": "D",
        "InputDataType": "S"
      },
      {
        "name": "customer_id",
        "value": "{{CustomerID}}",
        "InputType": "R",
        "InputValueType": "D",
        "InputDataType": "S"
      }
    ]
  },
  "apiOutput": [
    {
      "ResultFieldTag": "CustomerName",
      "ResultFieldName": "name",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "success_response",
      "ResultFieldName": "success",
      "IsSuccessValidator": true,
      "SuccessValue": "true"
    }
  ],
  "successMessageText": "Customer validated",
  "failureMessageText": "Invalid customer ID"
}
```

**Audio Files**:
- `enter_customer_id.wav`: "Please enter your 10-digit customer ID followed by the pound key"
- `invalid_customer_id.wav`: "Invalid customer ID. Please try again."
- `customer_not_found.wav`: "Customer not found in our system."

---

## Record Message

**Scenario**: Record caller's message and save to file.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 4000,
      "NodeName": "Recording Instructions",
      "OperationCode": 10,
      "VoiceFileId": "record_instructions.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 4001}
      ]
    },
    {
      "NodeId": 4001,
      "NodeName": "Record Message",
      "OperationCode": 40,
      "VoiceFileId": "record_beep.wav",
      "RecordingTypeId": 1,
      "InputTimeLimit": 180,
      "TagName": "MessageRecording",
      "ChildNodeConfig": [
        {"ChildNodeId": 4002}
      ]
    },
    {
      "NodeId": 4002,
      "NodeName": "Playback Options",
      "OperationCode": 30,
      "VoiceFileId": "playback_options.wav",
      "ValidKeys": "1,2,3",
      "InputTimeLimit": 10,
      "TagName": "PlaybackChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 4010, "InputKeys": "1"},
        {"ChildNodeId": 4001, "InputKeys": "2"},
        {"ChildNodeId": 4020, "InputKeys": "3"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav"
    },
    {
      "NodeId": 4010,
      "NodeName": "Play Recording",
      "OperationCode": 11,
      "TagName": "MessageRecording",
      "ChildNodeConfig": [
        {"ChildNodeId": 4002}
      ]
    },
    {
      "NodeId": 4020,
      "NodeName": "Save and Continue",
      "OperationCode": 10,
      "VoiceFileId": "message_saved.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 5000}
      ]
    }
  ]
}
```

**Audio Files**:
- `record_instructions.wav`: "Please record your message after the beep. Press pound when finished."
- `record_beep.wav`: "Beep!"
- `playback_options.wav`: "Press 1 to listen to your recording, 2 to re-record, or 3 to save and continue."
- `message_saved.wav`: "Your message has been saved."

---

## API Authentication

**Scenario**: Authenticate with external API at start of call.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1000,
      "NodeName": "System Authentication",
      "OperationCode": 111,
      "APIId": 10,
      "IsStartNode": true,
      "ChildNodeConfig": [
        {"ChildNodeId": 1001, "InputKeys": "S"},
        {"ChildNodeId": 1002, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 1001,
      "NodeName": "Auth Success",
      "OperationCode": 10,
      "VoiceFileId": "welcome.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 2000}
      ]
    },
    {
      "NodeId": 1002,
      "NodeName": "Auth Failed",
      "OperationCode": 10,
      "VoiceFileId": "system_error.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    }
  ]
}
```

### automax_webAPIConfig.json
```json
{
  "apiId": 10,
  "apiDescription": "Authentication API",
  "serviceURL": "https://api.example.com/auth/login",
  "methodType": "POST",
  "securityMode": "N",
  "inputMediaType": "application/json",
  "apiInput": [
    {
      "FieldName": "email",
      "InputType": "R",
      "InputValueType": "S",
      "InputDataType": "S",
      "InputValue": "ivr@example.com"
    },
    {
      "FieldName": "password",
      "InputType": "R",
      "InputValueType": "S",
      "InputDataType": "S",
      "InputValue": "SecurePassword123!"
    }
  ],
  "apiOutput": [
    {
      "ResultFieldTag": "Access_token",
      "ResultFieldName": "token",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "success_response",
      "ResultFieldName": "success",
      "IsSuccessValidator": true,
      "SuccessValue": "true"
    }
  ],
  "successMessageText": "Authentication successful",
  "failureMessageText": "Authentication failed"
}
```

---

## Create Incident with Recording

**Scenario**: Collect incident details and create ticket with audio attachment.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 5000,
      "NodeName": "Incident Category",
      "OperationCode": 30,
      "VoiceFileId": "select_category.wav",
      "ValidKeys": "1,2,3",
      "InputTimeLimit": 10,
      "TagName": "CategorySelection",
      "ChildNodeConfig": [
        {"ChildNodeId": 5001, "InputKeys": "1"},
        {"ChildNodeId": 5001, "InputKeys": "2"},
        {"ChildNodeId": 5001, "InputKeys": "3"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav"
    },
    {
      "NodeId": 5001,
      "NodeName": "Map Category to ID",
      "OperationCode": 120,
      "ChildNodeConfig": [
        {
          "ChildNodeId": 5010,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CategorySelection",
          "ComparisonOperator": "EQ",
          "Value1": "1"
        },
        {
          "ChildNodeId": 5010,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CategorySelection",
          "ComparisonOperator": "EQ",
          "Value1": "2"
        },
        {
          "ChildNodeId": 5010,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CategorySelection",
          "ComparisonOperator": "EQ",
          "Value1": "3"
        }
      ]
    },
    {
      "NodeId": 5010,
      "NodeName": "Record Incident Details",
      "OperationCode": 40,
      "VoiceFileId": "record_details_beep.wav",
      "RecordingTypeId": 2,
      "InputTimeLimit": 120,
      "TagName": "incident_recording",
      "ChildNodeConfig": [
        {"ChildNodeId": 5020}
      ]
    },
    {
      "NodeId": 5020,
      "NodeName": "Create Incident",
      "OperationCode": 111,
      "APIId": 12,
      "ChildNodeConfig": [
        {"ChildNodeId": 5030, "InputKeys": "S"},
        {"ChildNodeId": 5040, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 5030,
      "NodeName": "Upload Recording",
      "OperationCode": 111,
      "APIId": 23,
      "ChildNodeConfig": [
        {"ChildNodeId": 5050, "InputKeys": "S"},
        {"ChildNodeId": 5060, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 5050,
      "NodeName": "Success Confirmation",
      "OperationCode": 330,
      "APIId": 19,
      "DeafultInput": "Your incident {{ticket_number_response}} has been created successfully.",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 5040,
      "NodeName": "Incident Creation Failed",
      "OperationCode": 10,
      "VoiceFileId": "incident_failed.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 5060,
      "NodeName": "Upload Failed",
      "OperationCode": 10,
      "VoiceFileId": "upload_failed.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 5050}
      ]
    }
  ]
}
```

### automax_webAPIConfig.json
```json
{
  "apiId": 12,
  "apiDescription": "Create Incident API",
  "serviceURL": "https://api.example.com/incidents",
  "methodType": "POST",
  "securityMode": "A",
  "inputMediaType": "application/json",
  "apiInput": {
    "values": [
      {
        "name": "Authorization",
        "value": "Bearer {{Access_token}}",
        "InputType": "H",
        "InputValueType": "D",
        "InputDataType": "S"
      },
      {
        "name": "title",
        "value": "Incident reported via IVR",
        "InputType": "R",
        "InputValueType": "S",
        "InputDataType": "S"
      },
      {
        "name": "description",
        "value": "Audio recording attached",
        "InputType": "R",
        "InputValueType": "S",
        "InputDataType": "S"
      },
      {
        "name": "category_id",
        "value": "{{CategorySelection}}",
        "InputType": "R",
        "InputValueType": "D",
        "InputDataType": "S"
      },
      {
        "name": "priority",
        "value": "3",
        "InputType": "R",
        "InputValueType": "S",
        "InputDataType": "N"
      }
    ]
  },
  "apiOutput": [
    {
      "ResultFieldTag": "incident_id",
      "ResultFieldName": "id",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "ticket_number_response",
      "ResultFieldName": "ticket_number",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "success_response",
      "ResultFieldName": "success",
      "IsSuccessValidator": true,
      "SuccessValue": "true"
    }
  ],
  "successMessageText": "Incident created",
  "failureMessageText": "Failed to create incident"
},
{
  "apiId": 23,
  "apiDescription": "Upload Recording",
  "serviceURL": "https://api.example.com/incidents/{incident_id}/attachments",
  "methodType": "POST",
  "securityMode": "A",
  "inputMediaType": "multipart/form-data",
  "apiInput": [
    {
      "FieldName": "incident_id",
      "InputType": "U",
      "InputValueType": "D",
      "InputValue": "incident_id"
    },
    {
      "FieldName": "file",
      "InputType": "F",
      "InputValueType": "D",
      "InputValue": "incident_recording"
    },
    {
      "FieldName": "Authorization",
      "InputType": "H",
      "InputValueType": "D",
      "InputValue": "Bearer {{Access_token}}"
    }
  ],
  "apiOutput": [],
  "successMessageText": "Recording uploaded",
  "failureMessageText": "Upload failed"
}
```

---

## Transfer to Agent

**Scenario**: Transfer call to available agent or queue.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 6000,
      "NodeName": "Check Agent Availability",
      "OperationCode": 111,
      "APIId": 30,
      "ChildNodeConfig": [
        {"ChildNodeId": 6010, "InputKeys": "S"},
        {"ChildNodeId": 6020, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 6010,
      "NodeName": "Transfer to Agent",
      "OperationCode": 101,
      "ChildNodeConfig": [
        {"ChildNodeId": 6030, "InputKeys": "S"},
        {"ChildNodeId": 6040, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 6020,
      "NodeName": "No Agents Available",
      "OperationCode": 30,
      "VoiceFileId": "no_agents.wav",
      "ValidKeys": "1,2",
      "InputTimeLimit": 10,
      "TagName": "NoAgentChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 7000, "InputKeys": "1"},
        {"ChildNodeId": 6050, "InputKeys": "2"}
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "invalid.wav"
    },
    {
      "NodeId": 6030,
      "NodeName": "Transfer Successful",
      "OperationCode": 10,
      "VoiceFileId": "transferring.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    },
    {
      "NodeId": 6040,
      "NodeName": "Transfer Failed",
      "OperationCode": 10,
      "VoiceFileId": "transfer_failed.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 7000}
      ]
    },
    {
      "NodeId": 6050,
      "NodeName": "Return to Menu",
      "OperationCode": 10,
      "VoiceFileId": "returning_to_menu.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 1000}
      ]
    },
    {
      "NodeId": 7000,
      "NodeName": "Leave Voicemail",
      "OperationCode": 40,
      "VoiceFileId": "leave_message.wav",
      "RecordingTypeId": 3,
      "InputTimeLimit": 120,
      "TagName": "voicemail_recording",
      "ChildNodeConfig": [
        {"ChildNodeId": 7010}
      ]
    },
    {
      "NodeId": 7010,
      "NodeName": "Voicemail Confirmation",
      "OperationCode": 10,
      "VoiceFileId": "voicemail_saved.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 9999}
      ]
    }
  ]
}
```

**Audio Files**:
- `no_agents.wav`: "All agents are busy. Press 1 to leave a message, or 2 to return to the main menu."
- `transferring.wav`: "Please hold while we transfer your call."
- `transfer_failed.wav`: "We're unable to transfer your call at this time."
- `leave_message.wav`: "Please leave your message after the beep."
- `voicemail_saved.wav`: "Your message has been saved. An agent will contact you shortly."

---

## Business Hours Check

**Scenario**: Check if calling within business hours.

### GeneralSettingValues
```json
{
  "SettingId": 6,
  "SettingnKey": "IVRAvailablitySchedule",
  "SettingValue": "[{\"Day\":\"SUN\",\"Schedule\":{\"From\":\"9:00AM\",\"To\":\"5:00PM\"}},{\"Day\":\"MON\",\"Schedule\":{\"From\":\"9:00AM\",\"To\":\"5:00PM\"}},{\"Day\":\"TUE\",\"Schedule\":{\"From\":\"9:00AM\",\"To\":\"5:00PM\"}},{\"Day\":\"WED\",\"Schedule\":{\"From\":\"9:00AM\",\"To\":\"5:00PM\"}},{\"Day\":\"THU\",\"Schedule\":{\"From\":\"9:00AM\",\"To\":\"1:00PM\"}},{\"Day\":\"FRI\",\"Schedule\":{}},{\"Day\":\"SAT\",\"Schedule\":{}}]"
},
{
  "SettingId": 7,
  "SettingnKey": "IVRUnavailablityDates",
  "SettingValue": "12252024,01012025,07042025"
},
{
  "SettingId": 8,
  "SettingnKey": "IVRUnavailablityAudio",
  "SettingValue": "closed_message.wav"
}
```

**The system automatically checks business hours. If outside hours, it plays the unavailability audio and ends the call.**

---

## Dynamic Text-to-Speech

**Scenario**: Use TTS to speak dynamic content.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 8000,
      "NodeName": "Get Account Balance",
      "OperationCode": 111,
      "APIId": 25,
      "ChildNodeConfig": [
        {"ChildNodeId": 8010, "InputKeys": "S"},
        {"ChildNodeId": 8020, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 8010,
      "NodeName": "Speak Balance",
      "OperationCode": 330,
      "APIId": 19,
      "DeafultInput": "Your current account balance is {{AccountBalance}} dollars and {{AccountCents}} cents. Your next payment is due on {{DueDate}}.",
      "ChildNodeConfig": [
        {"ChildNodeId": 8030}
      ]
    },
    {
      "NodeId": 8020,
      "NodeName": "Balance Error",
      "OperationCode": 10,
      "VoiceFileId": "balance_unavailable.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 1000}
      ]
    },
    {
      "NodeId": 8030,
      "NodeName": "More Options",
      "OperationCode": 30,
      "VoiceFileId": "more_options.wav",
      "ValidKeys": "1,2",
      "InputTimeLimit": 10,
      "ChildNodeConfig": [
        {"ChildNodeId": 8040, "InputKeys": "1"},
        {"ChildNodeId": 1000, "InputKeys": "2"}
      ]
    }
  ]
}
```

### automax_webAPIConfig.json
```json
{
  "apiId": 25,
  "apiDescription": "Get Account Balance",
  "serviceURL": "https://api.example.com/accounts/{{CustomerID}}/balance",
  "methodType": "GET",
  "securityMode": "A",
  "inputMediaType": "application/json",
  "apiInput": {
    "values": [
      {
        "name": "Authorization",
        "value": "Bearer {{Access_token}}",
        "InputType": "H",
        "InputValueType": "D",
        "InputDataType": "S"
      }
    ]
  },
  "apiOutput": [
    {
      "ResultFieldTag": "AccountBalance",
      "ResultFieldName": "balance_dollars",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "AccountCents",
      "ResultFieldName": "balance_cents",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "DueDate",
      "ResultFieldName": "next_due_date",
      "ParentResultId": "data",
      "IsSuccessValidator": false
    },
    {
      "ResultFieldTag": "success_response",
      "ResultFieldName": "success",
      "IsSuccessValidator": true,
      "SuccessValue": "true"
    }
  ],
  "successMessageText": "Balance retrieved",
  "failureMessageText": "Failed to get balance"
}
```

---

## Conditional Routing

**Scenario**: Route based on customer type.

### ivrconfig.json
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 9000,
      "NodeName": "Check Customer Type",
      "OperationCode": 120,
      "ChildNodeConfig": [
        {
          "ChildNodeId": 9100,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CustomerType",
          "ComparisonOperator": "EQ",
          "Value1": "VIP"
        },
        {
          "ChildNodeId": 9200,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CustomerType",
          "ComparisonOperator": "EQ",
          "Value1": "Premium"
        },
        {
          "ChildNodeId": 9300,
          "ApplyComparison": true,
          "OperandType": "D",
          "CollectionTag": "CustomerType",
          "ComparisonOperator": "EQ",
          "Value1": "Standard"
        },
        {
          "ChildNodeId": 9300,
          "InputKeys": "*"
        }
      ]
    },
    {
      "NodeId": 9100,
      "NodeName": "VIP Flow",
      "OperationCode": 10,
      "VoiceFileId": "vip_welcome.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 6010}
      ]
    },
    {
      "NodeId": 9200,
      "NodeName": "Premium Flow",
      "OperationCode": 10,
      "VoiceFileId": "premium_welcome.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 2000}
      ]
    },
    {
      "NodeId": 9300,
      "NodeName": "Standard Flow",
      "OperationCode": 10,
      "VoiceFileId": "standard_welcome.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 1000}
      ]
    }
  ]
}
```

---

## Complete Customer Service Flow

**Scenario**: Full customer service IVR with all features.

### ivrconfig.json (Simplified Structure)
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1000,
      "NodeName": "Start - Welcome",
      "OperationCode": 10,
      "VoiceFileId": "welcome.wav",
      "IsStartNode": true,
      "ChildNodeConfig": [{"ChildNodeId": 1010}]
    },
    {
      "NodeId": 1010,
      "NodeName": "Language Selection",
      "OperationCode": 30,
      "VoiceFileId": "language_prompt.wav",
      "ValidKeys": "1,2",
      "IsLanguageSelect": true,
      "TagName": "LanguageSelected",
      "ChildNodeConfig": [
        {"ChildNodeId": 1100, "InputKeys": "1"},
        {"ChildNodeId": 1200, "InputKeys": "2"}
      ]
    },
    {
      "NodeId": 1100,
      "NodeName": "Auth (EN)",
      "OperationCode": 111,
      "APIId": 10,
      "ChildNodeConfig": [
        {"ChildNodeId": 2000, "InputKeys": "S"},
        {"ChildNodeId": 9999, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 2000,
      "NodeName": "Customer ID (EN)",
      "OperationCode": 105,
      "VoiceFileId": "enter_customer_id_en.wav",
      "ValidKeys": "0,1,2,3,4,5,6,7,8,9,#",
      "InputLength": 10,
      "TagName": "CustomerID",
      "ChildNodeConfig": [{"ChildNodeId": 2010}]
    },
    {
      "NodeId": 2010,
      "NodeName": "Validate Customer (EN)",
      "OperationCode": 111,
      "APIId": 15,
      "ChildNodeConfig": [
        {"ChildNodeId": 2020, "InputKeys": "S"},
        {"ChildNodeId": 2000, "InputKeys": "F"}
      ]
    },
    {
      "NodeId": 2020,
      "NodeName": "Check Customer Type",
      "OperationCode": 120,
      "ChildNodeConfig": [
        {
          "ChildNodeId": 3000,
          "ApplyComparison": true,
          "CollectionTag": "CustomerType",
          "ComparisonOperator": "EQ",
          "Value1": "VIP"
        },
        {"ChildNodeId": 3100, "InputKeys": "*"}
      ]
    },
    {
      "NodeId": 3000,
      "NodeName": "VIP Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "vip_menu_en.wav",
      "ValidKeys": "1,2,3,0",
      "TagName": "VIPMenuChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 4000, "InputKeys": "1"},
        {"ChildNodeId": 5000, "InputKeys": "2"},
        {"ChildNodeId": 6000, "InputKeys": "3"},
        {"ChildNodeId": 6010, "InputKeys": "0"}
      ]
    },
    {
      "NodeId": 3100,
      "NodeName": "Standard Main Menu",
      "OperationCode": 30,
      "VoiceFileId": "main_menu_en.wav",
      "ValidKeys": "1,2,3,0",
      "TagName": "MenuChoice",
      "ChildNodeConfig": [
        {"ChildNodeId": 4000, "InputKeys": "1"},
        {"ChildNodeId": 5000, "InputKeys": "2"},
        {"ChildNodeId": 6000, "InputKeys": "3"},
        {"ChildNodeId": 7000, "InputKeys": "0"}
      ]
    },
    {
      "NodeId": 4000,
      "NodeName": "Account Balance",
      "OperationCode": 111,
      "APIId": 25,
      "ChildNodeConfig": [
        {"ChildNodeId": 4010, "InputKeys": "S"}
      ]
    },
    {
      "NodeId": 4010,
      "NodeName": "Speak Balance",
      "OperationCode": 330,
      "APIId": 19,
      "DeafultInput": "Your balance is {{AccountBalance}} dollars.",
      "ChildNodeConfig": [{"ChildNodeId": 3100}]
    },
    {
      "NodeId": 5000,
      "NodeName": "Report Incident",
      "OperationCode": 40,
      "RecordingTypeId": 1,
      "TagName": "incident_recording",
      "ChildNodeConfig": [{"ChildNodeId": 5010}]
    },
    {
      "NodeId": 5010,
      "NodeName": "Create Incident",
      "OperationCode": 111,
      "APIId": 12,
      "ChildNodeConfig": [
        {"ChildNodeId": 5020, "InputKeys": "S"}
      ]
    },
    {
      "NodeId": 5020,
      "NodeName": "Upload Recording",
      "OperationCode": 111,
      "APIId": 23,
      "ChildNodeConfig": [
        {"ChildNodeId": 5030, "InputKeys": "S"}
      ]
    },
    {
      "NodeId": 5030,
      "NodeName": "Incident Confirmation",
      "OperationCode": 330,
      "APIId": 19,
      "DeafultInput": "Incident {{ticket_number_response}} created.",
      "ChildNodeConfig": [{"ChildNodeId": 3100}]
    },
    {
      "NodeId": 6000,
      "NodeName": "Transfer to Support",
      "OperationCode": 101,
      "ChildNodeConfig": [{"ChildNodeId": 9999}]
    },
    {
      "NodeId": 6010,
      "NodeName": "Direct Transfer (VIP)",
      "OperationCode": 100,
      "ChildNodeConfig": [{"ChildNodeId": 9999}]
    },
    {
      "NodeId": 7000,
      "NodeName": "General Queue",
      "OperationCode": 101,
      "ChildNodeConfig": [{"ChildNodeId": 9999}]
    },
    {
      "NodeId": 9999,
      "NodeName": "End Call",
      "OperationCode": 200
    }
  ]
}
```

---

## Tips for Creating Configurations

1. **Node IDs**: Use sequential IDs (1000, 1001, etc.) for better organization
2. **Start Node**: Always have exactly ONE node with `IsStartNode: true`
3. **Error Paths**: Always include "X" and "T" paths in ChildNodeConfig
4. **Timeouts**: Use 10 seconds for menus, 30 seconds for input collection
5. **Repeat Limits**: Keep between 3-5 to prevent frustration
6. **API Security**: Always use `securityMode: "A"` for authenticated APIs
7. **Variable Names**: Use descriptive names like `CustomerID`, `IncidentRecording`
8. **Audio Files**: Use descriptive filenames like `main_menu_en.wav`
9. **Validation**: Test all paths (happy path, error path, timeout)
10. **Comments**: Add clear NodeName values for debugging

---

**See DOCUMENTATION.md for detailed explanations of all configuration options.**
