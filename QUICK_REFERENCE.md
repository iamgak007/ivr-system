# IVR System - Quick Reference Guide

## Configuration Files Quick Reference

### ivrconfig.json - Node Configuration

```json
{
  "NodeId": 1001,                          // Unique node identifier
  "NodeName": "Welcome",                   // Human-readable name
  "OperationCode": 30,                     // What operation to perform (see table below)
  "VoiceFileId": "welcome.wav",            // Audio file to play
  "APIId": 10,                             // Reference to API in automax_webAPIConfig.json
  "IsStartNode": true,                     // Entry point (only one should be true)
  "ValidKeys": "1,2,3",                    // Acceptable DTMF inputs
  "RepeatLimit": 3,                        // Max repetitions on invalid input
  "InputTimeLimit": 10,                    // Seconds to wait for input
  "TagName": "MenuSelection",              // Session variable to store result
  "IsLanguageSelect": false,               // Is this a language selection node?
  "InvalidInputVoiceFileId": "invalid.wav",// Audio for invalid input
  "DeafultInput": "default text",          // Default value if no input
  "ChildNodeConfig": [                     // Possible next nodes
    {
      "ChildNodeId": 1002,                 // Target node ID
      "InputKeys": "1",                    // Input that triggers this path
      "ApplyComparison": false,            // Use conditional logic?
      "ComparisonOperator": "EQ",          // For conditional: EQ, GT, LT, etc.
      "CollectionTag": "variable_name",    // Variable to compare
      "Value1": "expected_value"           // Comparison value
    }
  ]
}
```

### automax_webAPIConfig.json - API Configuration

```json
{
  "apiId": 10,                             // Unique API identifier
  "apiDescription": "Authentication API",  // Human-readable name
  "serviceURL": "https://api.example.com/endpoint",  // Full URL
  "methodType": "POST",                    // HTTP method: GET, POST
  "securityMode": "A",                     // N=None, A=Auth Required
  "inputMediaType": "application/json",    // Content-Type

  "apiInput": {                            // Request configuration
    "values": [
      {
        "name": "Authorization",           // Field name
        "value": "Bearer {{token}}",       // Value (use {{var}} for session vars)
        "InputType": "H",                  // H=Header, R=Body, U=URL, F=File
        "InputValueType": "D",             // S=Static, D=Dynamic, E=Environment
        "InputDataType": "S",              // S=String, N=Number, B=Boolean
        "DefaultValue": "fallback"         // Used if variable not found
      }
    ]
  },

  "apiOutput": [                           // Response parsing
    {
      "ResultFieldTag": "Access_token",    // Session variable name to store
      "ResultFieldName": "token",          // Field name in JSON response
      "ParentResultId": "data",            // Parent object path (null for root)
      "IsList": false,                     // Is response an array?
      "ListIndex": 0,                      // Array index if IsList=true
      "IsSuccessValidator": true,          // Use to determine success?
      "SuccessValue": "true",              // Expected value for success
      "DefaultValue": ""                   // Fallback if field missing
    }
  ],

  "successMessageText": "Success message",
  "failureMessageText": "Failure message"
}
```

---

## Operation Code Reference

| Code | Name | Module | Description | Required Fields |
|------|------|--------|-------------|-----------------|
| **10** | Play Audio | audio | Play audio file | VoiceFileId |
| **11** | Play Recorded | audio | Play recorded file from session | TagName (source) |
| **20** | Get Input | input | Collect DTMF input | ValidKeys, InputTimeLimit, TagName |
| **30** | Audio + Input | audio | Play audio then get input | VoiceFileId, ValidKeys, TagName |
| **31** | Menu | audio | Play menu and get selection | VoiceFileId, ValidKeys, TagName |
| **40** | Record | recording | Record caller message | RecordingTypeId, TagName |
| **50** | Play Number | audio | Play number sequence | TagName (source number) |
| **100** | Transfer Ext | transfer | Transfer to extension | Extension number |
| **101** | Transfer Queue | transfer | Transfer to call center | Queue config |
| **105** | Multi-Input | input | Multi-digit input | InputLength, TagName |
| **107** | Blind Transfer | transfer | Blind transfer | Extension |
| **108** | Attended Transfer | transfer | Attended transfer | Extension |
| **111** | API Call | api | HTTP API request | APIId |
| **112** | API POST | api | Simple POST | APIId |
| **120** | Logic | logic | Conditional branching | ChildNodeConfig with conditions |
| **200** | Terminate | termination | End call | VoiceFileId (goodbye message) |
| **222** | API Auth | api | Authentication call | APIId |
| **330** | TTS | tts | Text-to-speech | DeafultInput, APIId |
| **331** | TTS + Input | tts | TTS with input | DeafultInput, ValidKeys, APIId |
| **341** | Record Options | recording | Advanced recording | RecordingTypeId, options |

---

## Special InputKeys Values

| Value | Meaning | When Used |
|-------|---------|-----------|
| `"1"`, `"2"`, etc. | Specific DTMF digit | User pressed this key |
| `"X"` | Invalid input | User entered invalid DTMF |
| `"T"` | Timeout | No input within InputTimeLimit |
| `"S"` | Success | API call succeeded |
| `"F"` | Failure | API call failed |
| `"*"` | Default/Catch-all | Any other case |

---

## API Input Types

| InputType | Description | Where Used | Example |
|-----------|-------------|------------|---------|
| **R** | Request Body | POST/PUT body | `{"name": "value"}` |
| **H** | Header | HTTP headers | `Authorization: Bearer token` |
| **U** | URL Parameter | Path/query params | `/incidents/{id}` |
| **F** | File Upload | Multipart form | Recording files |
| **B** | Binary Body | Raw binary data | Audio/image data |

---

## API Input Value Types

| InputValueType | Description | Example |
|----------------|-------------|---------|
| **S** | Static | Hard-coded: `"admin@example.com"` |
| **D** | Dynamic | Session variable: `{{CustomerName}}` |
| **E** | Environment | System variable: `Call_Log_Id` |

---

## Comparison Operators (Operation 120)

| Operator | Description | Example |
|----------|-------------|---------|
| **EQ** | Equal | CustomerType == "Premium" |
| **NE** | Not Equal | Status != "Active" |
| **GT** | Greater Than | Balance > 1000 |
| **LT** | Less Than | Age < 18 |
| **GE** | Greater or Equal | Score >= 80 |
| **LE** | Less or Equal | Attempts <= 3 |
| **CONTAINS** | String contains | Email contains "@gmail" |
| **STARTS_WITH** | String starts | Phone starts with "+1" |
| **ENDS_WITH** | String ends | Filename ends with ".wav" |
| **IS_EMPTY** | Is null/empty | Description is empty |
| **IS_NOT_EMPTY** | Has value | Name is not empty |

---

## Session Variable Usage

### Setting Variables
```json
{
  "OperationCode": 20,
  "TagName": "MenuSelection"
}
```
Stores user input in `MenuSelection` variable.

### Reading Variables in APIs
```json
{
  "name": "customer_id",
  "value": "{{MenuSelection}}"
}
```
Uses the `MenuSelection` variable value.

### Reading Variables in TTS
```json
{
  "OperationCode": 330,
  "DeafultInput": "Welcome {{CustomerName}}, your balance is {{Balance}}"
}
```

---

## Common Node Patterns

### 1. Simple Audio Playback
```json
{
  "NodeId": 1001,
  "OperationCode": 10,
  "VoiceFileId": "welcome.wav",
  "ChildNodeConfig": [{"ChildNodeId": 1002}]
}
```

### 2. Menu with Input
```json
{
  "NodeId": 1002,
  "OperationCode": 30,
  "VoiceFileId": "menu.wav",
  "ValidKeys": "1,2,3",
  "InputTimeLimit": 10,
  "TagName": "MenuChoice",
  "RepeatLimit": 3,
  "InvalidInputVoiceFileId": "invalid.wav",
  "ChildNodeConfig": [
    {"ChildNodeId": 2001, "InputKeys": "1"},
    {"ChildNodeId": 2002, "InputKeys": "2"},
    {"ChildNodeId": 2003, "InputKeys": "3"},
    {"ChildNodeId": 9999, "InputKeys": "X"}
  ]
}
```

### 3. Record Message
```json
{
  "NodeId": 3001,
  "OperationCode": 40,
  "VoiceFileId": "record_beep.wav",
  "RecordingTypeId": 1,
  "TagName": "recording_path",
  "InputTimeLimit": 120,
  "ChildNodeConfig": [{"ChildNodeId": 3002}]
}
```

### 4. API Call with Success/Failure Paths
```json
{
  "NodeId": 4001,
  "OperationCode": 111,
  "APIId": 12,
  "ChildNodeConfig": [
    {"ChildNodeId": 4100, "InputKeys": "S"},
    {"ChildNodeId": 4200, "InputKeys": "F"}
  ]
}
```

### 5. Conditional Branch
```json
{
  "NodeId": 5001,
  "OperationCode": 120,
  "ChildNodeConfig": [
    {
      "ChildNodeId": 5010,
      "ApplyComparison": true,
      "OperandType": "D",
      "CollectionTag": "CustomerType",
      "ComparisonOperator": "EQ",
      "Value1": "VIP"
    },
    {
      "ChildNodeId": 5020,
      "InputKeys": "*"
    }
  ]
}
```

---

## File Structure at a Glance

```
main.lua                        → Entry point
├─ config/init.lua             → Load configs
├─ core/
│  ├─ init.lua                 → Initialize system
│  ├─ call_flow.lua            → Execute node flow
│  ├─ operation_dispatcher.lua → Route operations
│  └─ session_manager.lua      → Manage variables
├─ operations/
│  ├─ audio.lua                → Ops 10,11,30,31,50
│  ├─ input.lua                → Ops 20,105
│  ├─ recording.lua            → Ops 40,341
│  ├─ transfer.lua             → Ops 100,101,107,108
│  ├─ api.lua                  → Ops 111,112,222
│  ├─ logic.lua                → Op 120
│  ├─ termination.lua          → Op 200
│  └─ tts.lua                  → Ops 330,331
└─ services/
   ├─ http_client.lua          → HTTP requests
   ├─ auth_service.lua         → Authentication
   ├─ incident_service.lua     → Ticket creation
   └─ attachment_service.lua   → File uploads
```

---

## Debugging Tips

### Check Logs
```lua
-- In FreeSWITCH console
fs_cli -x "console loglevel debug"

-- Check specific module logs
logger:info("Current node: " .. node.NodeId)
logger:debug("Variable value: " .. session_manager.get_variable("var_name"))
```

### Validate Configurations
1. **ivrconfig.json**: Ensure valid JSON (use jsonlint.com)
2. **IsStartNode**: Exactly one node should have this set to true
3. **ChildNodeConfig**: Every node should have at least one child (except termination)
4. **ValidKeys**: Match InputKeys in children

### Test API Calls
```bash
# Test API manually with curl
curl -X POST https://api.example.com/endpoint \
  -H "Authorization: Bearer token" \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}'
```

### Common Variable Names
```
Access_token           - Auth token from login API
LanguageSelected       - User language choice (1=AR, 2=EN)
CustomerName           - Caller name
recording_file_path    - Path to recorded audio
incident_no_response   - Created incident ID
success_response       - API call success status
```

---

## Performance Tips

1. **Caching**: Config files are cached; modify only when needed
2. **Audio Files**: Use compressed WAV format (8kHz, 16-bit)
3. **API Timeouts**: Set reasonable timeouts (default: 30s)
4. **Repeat Limits**: Keep between 3-5 to prevent call loops
5. **Input Timeouts**: 5-10 seconds for menu selections

---

## Need More Details?

See **DOCUMENTATION.md** for:
- Complete architecture overview
- Detailed module documentation
- Extended examples
- Troubleshooting guide
- Best practices

---

**Quick Start**: Edit `ivrconfig.json` → Define nodes → Set operation codes → Configure routing → Test!
