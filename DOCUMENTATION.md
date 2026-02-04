# IVR System - Comprehensive Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Directory Structure](#directory-structure)
3. [Configuration Files](#configuration-files)
4. [System Flow](#system-flow)
5. [Node Operations](#node-operations)
6. [Core Modules](#core-modules)
7. [Operation Modules](#operation-modules)
8. [Service Modules](#service-modules)
9. [Utility Modules](#utility-modules)
10. [Examples](#examples)

---

## System Overview

This is an advanced **Interactive Voice Response (IVR)** system built for FreeSWITCH telephony platform using Lua. The system provides a flexible, configuration-driven approach to building complex call flows with support for:

- Multi-language support (Arabic, English)
- DTMF input collection
- Audio playback and recording
- Text-to-Speech (TTS) and Speech-to-Text (STT)
- Call transfers and routing
- External API integration
- Incident/ticket creation
- Conditional logic and branching

---

## Directory Structure

```
ivr-system-03-02-2026/
│
├── main.lua                        # Entry point for the IVR system
├── old_ivr_main.lua               # Legacy main file (deprecated)
│
├── automax_webAPIConfig.json      # Web API endpoint configurations
├── ivrconfig.json                 # IVR flow and node definitions (14,710 lines)
│
├── config/                        # Configuration management
│   └── init.lua                   # Config loader with caching & validation
│
├── core/                          # Core system components
│   ├── init.lua                   # Core module initializer
│   ├── call_flow.lua              # Call flow orchestration
│   ├── operation_dispatcher.lua   # Operation routing engine
│   └── session_manager.lua        # Session state management
│
├── operations/                    # Operation handlers (what each node does)
│   ├── api.lua                    # API integration operations (111, 112, 222)
│   ├── audio.lua                  # Audio playback operations (10, 11, 30, 31, 50)
│   ├── input.lua                  # DTMF input collection (20, 105)
│   ├── logic.lua                  # Conditional logic (120)
│   ├── recording.lua              # Voice recording (40, 341)
│   ├── termination.lua            # Call termination (200)
│   ├── transfer.lua               # Call transfer operations (100, 101, 107, 108)
│   └── tts.lua                    # Text-to-Speech operations (330, 331)
│
├── services/                      # Business logic services
│   ├── init.lua                   # Service initializer
│   ├── auth_service.lua           # Authentication handling
│   ├── attachment_service.lua     # File attachment management
│   ├── cache_manager.lua          # Caching layer
│   ├── http_client.lua            # HTTP request handling
│   └── incident_service.lua       # Incident/ticket creation
│
└── utils/                         # Utility functions
    ├── init.lua                   # Utility module loader
    ├── file_utils.lua             # File operations
    ├── json_utils.lua             # JSON parsing/encoding
    ├── logging.lua                # Logging framework
    ├── string_utils.lua           # String manipulation
    └── validators.lua             # Input validation

```

### Directory Purposes

#### **`/config`**
- **Purpose**: Manages all configuration loading, caching, and validation
- **Key Features**:
  - Hot-reloading (detects file changes)
  - In-memory caching with TTL
  - Validation of configuration structure

#### **`/core`**
- **Purpose**: Core engine that drives the entire IVR system
- **Responsibilities**:
  - Initialize the system
  - Manage call flow execution
  - Route operations to appropriate handlers
  - Manage session state and variables

#### **`/operations`**
- **Purpose**: Implementation of specific IVR node operations
- **What it does**: Each file handles a category of operations (audio, input, API calls, etc.)
- **How it works**: The dispatcher routes operation codes to these modules

#### **`/services`**
- **Purpose**: Reusable business logic services
- **Examples**:
  - Making HTTP API calls
  - Creating incidents/tickets
  - Uploading attachments
  - Authentication

#### **`/utils`**
- **Purpose**: Low-level utility functions used across the system
- **Examples**: JSON parsing, logging, string manipulation, file operations

---

## Configuration Files

### 1. **`ivrconfig.json`** - IVR Flow Configuration

**Purpose**: This is the heart of the IVR system. It defines the entire call flow structure including nodes, operations, routing logic, and system settings.

**Size**: 14,710 lines (very large, node-based configuration)

#### Structure

```json
{
  "IVRConfiguration": [
    {
      "IVRId": 1,
      "IVRCode": "EPM940",
      "IVRName": "EPM940",
      "GeneralSettingValues": [...],
      "IVRProcessFlow": [...]
    }
  ]
}
```

#### **A. GeneralSettingValues**
System-wide settings that control IVR behavior.

**Available Settings:**

| Setting Key | Description | Example Value |
|------------|-------------|---------------|
| `BusyTone` | Audio file for busy signal | `"com_busytone.wav"` |
| `WaitTone` | Audio file while waiting | `"com_waittone.wav"` |
| `HoldTone` | Audio file when on hold | `"com_holdtone.wav"` |
| `AgentRedirectTone` | Audio for agent transfers | `"com_agentredirecttone.wav"` |
| `IVRAvailablitySchedule` | Business hours schedule | JSON array with day/time |
| `IVRUnavailablityDates` | Holidays/closed dates | `"10092023,20092023"` |
| `IVRUnavailablityAudio` | Message when closed | `"com_ivrunavailablitymessage.wav"` |
| `ExternalSIPLines` | SIP trunk configurations | JSON array of SIP lines |
| `TextToSpeechConfig` | TTS API configuration | `{"APIId": 19, ...}` |
| `SpeechToTextConfig` | STT API configuration | `{"APIId": 20, ...}` |
| `LanguageList` | Supported languages | JSON array with language configs |

**Example GeneralSettingValues:**

```json
{
  "SettingId": 15,
  "SettingnKey": "LanguageList",
  "SettingValue": "[{
    \"LanguageCode\": 2,
    \"LanguageName\": \"English\",
    \"TTSLanguageCode\": \"en-US\",
    \"STTLanguageCode\": \"en-US\",
    \"TTSVoiceNameBuiltIn\": \"rms\",
    \"TTSVoiceNameCloud\": \"en-US-GuyNeural\"
  },{
    \"LanguageCode\": 1,
    \"LanguageName\": \"Arabic\",
    \"TTSLanguageCode\": \"ar-SA\",
    \"STTLanguageCode\": \"ar-SA\",
    \"TTSVoiceNameBuiltIn\": \"ar-SA-ZariyahNeural\",
    \"TTSVoiceNameCloud\": \"ar-SA-ZariyahNeural\"
  }]"
}
```

#### **B. IVRProcessFlow**
Defines the call flow as a graph of interconnected nodes.

**Node Structure:**

```json
{
  "NodeId": 1001,
  "NodeName": "Welcome Message",
  "AltNodeName": "Welcome Message",
  "OperationCode": 10,
  "VoiceFileId": "welcome.wav",
  "APIId": null,
  "IsStartNode": true,
  "ChildNodeConfig": [...],
  "RepeatLimit": 0,
  "AudioPauseLength": 0,
  "RecordingTypeId": null,
  "InvalidResponseTypeCode": null,
  "ValidKeys": null,
  "InputType": null,
  "InputLength": 0,
  "IsLanguageSelect": false,
  "InputTimeLimit": 0,
  "TimeLimitResponseType": null,
  "InvalidInputVoiceFileId": null,
  "TagName": null,
  "DeafultInput": null,
  "IsRepetitive": false
}
```

**Key Node Fields:**

| Field | Description | Used For |
|-------|-------------|----------|
| `NodeId` | Unique identifier for the node | Navigation & routing |
| `NodeName` | Human-readable name | Debugging & logging |
| `OperationCode` | Operation type (10, 20, 30, etc.) | Determines what action to perform |
| `VoiceFileId` | Audio file to play | Audio operations |
| `APIId` | Reference to API config | API operations |
| `IsStartNode` | Entry point flag | Identifies where call flow begins |
| `ChildNodeConfig` | Array of possible next nodes | Call flow routing |
| `ValidKeys` | Acceptable DTMF inputs | Input validation |
| `RepeatLimit` | Max times to repeat prompt | Error handling |
| `InputTimeLimit` | Seconds to wait for input | Timeout handling |
| `TagName` | Variable name to store input | Data capture |

**ChildNodeConfig Structure:**

```json
{
  "ChildNodeId": 1002,
  "InputKeys": "1",
  "SaveInputToDB": false,
  "ApplyComparison": false,
  "OperandType": null,
  "ComparisonOperator": null,
  "Value1": null,
  "Value2": null
}
```

**Why It's Used:**
- **Dynamic Call Flow**: Configure complex call flows without changing code
- **Multi-path Routing**: Branch based on user input or conditions
- **Language Support**: Different flows for different languages
- **Easy Updates**: Modify call flow by editing JSON, no code changes

---

### 2. **`automax_webAPIConfig.json`** - Web API Configuration

**Purpose**: Defines all external API endpoints that the IVR can call, including authentication, incident creation, attachments, TTS/STT services, and more.

**Size**: 679 lines

#### Structure

```json
{
  "status": "SUCCESS",
  "message": "Web API information is fetched successfully",
  "result": [
    {
      "apiId": 10,
      "apiDescription": "Authentication API",
      "apiType": 1,
      "serviceURL": "https://ax3.automaxsw.com/api/v1/auth/login",
      "methodType": "POST",
      "securityMode": "N",
      "inputMediaType": "application/json",
      "apiInput": [...],
      "apiOutput": [...],
      "successMessageText": "Authentication is Success",
      "failureMessageText": "Authentication is Failed"
    },
    ...
  ]
}
```

#### API Configuration Fields

| Field | Description | Values |
|-------|-------------|--------|
| `apiId` | Unique API identifier | 10, 11, 12, 19, 20, etc. |
| `apiDescription` | Human-readable name | "Authentication API" |
| `apiType` | Type of API | 1 = REST API |
| `serviceURL` | Endpoint URL | Full URL with optional {placeholders} |
| `methodType` | HTTP method | "GET", "POST" |
| `securityMode` | Auth requirement | "N" = None, "A" = Auth Required |
| `inputMediaType` | Content-Type | "application/json", "multipart/form-data" |
| `apiInput` | Input parameters | Array or object of input fields |
| `apiOutput` | Output field mappings | Array of expected response fields |
| `successMessageText` | Success feedback | Message to play on success |
| `failureMessageText` | Error feedback | Message to play on failure |

#### API Input Configuration

**Input Types:**

| InputType | Description | Example |
|-----------|-------------|---------|
| `R` | Request Body | JSON payload fields |
| `H` | Header | Authorization, Content-Type |
| `U` | URL Parameter | {incident_id} in path |
| `F` | File Upload | Multipart file field |
| `B` | Binary Body | Raw audio/file data |

**Input Value Types:**

| InputValueType | Description | Example |
|----------------|-------------|---------|
| `S` | Static Value | Hard-coded string/number |
| `D` | Dynamic Value | Variable from session ({{variable_name}}) |
| `E` | Environment Variable | System variable |

**Example API Input (JSON format):**

```json
{
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
      "value": "{{IncidentTitleTextEn}}",
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
}
```

#### API Output Configuration

Maps response fields to session variables for use in subsequent nodes.

```json
[
  {
    "ResultFieldTag": "Access_token",
    "ResultFieldName": "token",
    "ParentResultId": "data",
    "IsList": false,
    "ListIndex": 0,
    "OutputFieldId": 1,
    "DefaultValue": "",
    "IsSuccessValidator": false,
    "SuccessValue": ""
  },
  {
    "ResultFieldTag": "success_response",
    "ResultFieldName": "success",
    "ParentResultId": null,
    "IsList": false,
    "IsSuccessValidator": true,
    "SuccessValue": "true"
  }
]
```

**Output Field Mapping:**

| Field | Description |
|-------|-------------|
| `ResultFieldTag` | Variable name to store in session |
| `ResultFieldName` | Field name in JSON response |
| `ParentResultId` | Parent object path (e.g., "data.user") |
| `IsList` | Whether response is an array |
| `IsSuccessValidator` | Use to determine API success |
| `SuccessValue` | Expected value for success |
| `DefaultValue` | Fallback if field missing |

**Why It's Used:**
- **Centralized API Management**: All API configs in one place
- **No Code Changes**: Add/modify APIs without touching code
- **Dynamic Variables**: Use session variables in API calls
- **Error Handling**: Defined success/failure messages
- **Field Mapping**: Automatically extract response data

---

## System Flow

### High-Level Call Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. FreeSWITCH receives incoming call                            │
│    └──> Executes main.lua                                       │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. main.lua: Initialize System                                  │
│    ├─> Setup package paths                                      │
│    ├─> Load core, config, utils modules                         │
│    ├─> Validate FreeSWITCH session                              │
│    └─> Log call information (UUID, Caller ID)                   │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. config.load_all(): Load Configuration Files                  │
│    ├─> ivrconfig.json (flow, nodes, settings)                   │
│    ├─> automax_webAPIConfig.json (API endpoints)                │
│    ├─> Extensions_qa.json (agent extensions)                    │
│    └─> RecordingType_qa.json (recording configs)                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. core.initialize(session): Initialize Core System             │
│    ├─> session_manager.initialize() - Setup session context     │
│    ├─> Cache configurations                                     │
│    └─> Initialize services (auth, incident, cache, http)        │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. call_flow.start(): Begin IVR Flow                            │
│    ├─> Find start node (IsStartNode: true)                      │
│    ├─> Answer the call                                          │
│    └─> Enter main processing loop                               │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Main Processing Loop (for each node)                         │
│    ┌───────────────────────────────────────────────────────────┐
│    │ a. Get current node from IVRProcessFlow                   │
│    │ b. Log node execution                                     │
│    │ c. Dispatch operation to handler                          │
│    │    └──> operation_dispatcher.execute(opCode, nodeData)    │
│    │                                                            │
│    │ d. Operation executes:                                    │
│    │    ├─> Audio: Play sound file                             │
│    │    ├─> Input: Collect DTMF digits                         │
│    │    ├─> Recording: Record caller audio                     │
│    │    ├─> API: Call external web service                     │
│    │    ├─> Transfer: Transfer call to agent                   │
│    │    ├─> TTS: Convert text to speech                        │
│    │    ├─> Logic: Evaluate conditions                         │
│    │    └─> Termination: End call                              │
│    │                                                            │
│    │ e. Determine next node:                                   │
│    │    ├─> Based on user input (DTMF)                         │
│    │    ├─> Based on condition evaluation                      │
│    │    └─> Based on API response                              │
│    │                                                            │
│    │ f. Update session variables                               │
│    │ g. Move to next node or exit                              │
│    └───────────────────────────────────────────────────────────┘
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Call Termination                                             │
│    ├─> Clean up resources                                       │
│    ├─> Log call statistics                                      │
│    └─> Hangup call                                              │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Node Processing Flow

```
┌───────────────────────────────────┐
│  Node Execution Starts            │
└────────────┬──────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────────┐
│ operation_dispatcher.execute(operation_code, node_data)        │
│                                                                 │
│ Maps operation code to module:                                 │
│   10,11,30,31,50 ──> operations.audio                          │
│   20,105         ──> operations.input                          │
│   40,341         ──> operations.recording                      │
│   100,101,107,108──> operations.transfer                       │
│   111,112,222    ──> operations.api                            │
│   120            ──> operations.logic                          │
│   200            ──> operations.termination                    │
│   330,331        ──> operations.tts                            │
└────────────┬───────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ Operation Module Executes          │
│ (e.g., operations.audio)           │
│                                    │
│ - Performs operation logic         │
│ - Interacts with FreeSWITCH        │
│ - Updates session variables        │
│ - Returns result/next node info    │
└────────────┬───────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ call_flow determines next node:    │
│                                    │
│ - Check ChildNodeConfig array      │
│ - Match user input against         │
│   InputKeys                        │
│ - Apply any conditional logic      │
│ - Handle special cases:            │
│   * "X" = Invalid input            │
│   * "T" = Timeout                  │
│   * "*" = Default path             │
└────────────┬───────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ Move to Next Node or Exit          │
└────────────────────────────────────┘
```

---

## Node Operations

### Operation Code Mapping

The `OperationCode` field in each node determines what action is performed.

| Operation Code | Name | Module | Description |
|----------------|------|--------|-------------|
| **10** | Play Audio | audio.lua | Play a pre-recorded audio file |
| **11** | Play Recorded | audio.lua | Play a previously recorded file |
| **20** | Get Input | input.lua | Collect DTMF input (single/multi digit) |
| **30** | Audio + Input | audio.lua | Play audio then collect DTMF |
| **31** | Menu Options | audio.lua | Play menu and get selection |
| **40** | Record | recording.lua | Record caller's voice message |
| **50** | Play Number | audio.lua | Play a number sequence (TTS) |
| **100** | Transfer Extension | transfer.lua | Transfer to specific extension |
| **101** | Transfer Queue | transfer.lua | Transfer to call center queue |
| **105** | Multi-Digit Input | input.lua | Collect multi-digit input (e.g., ID) |
| **107** | Blind Transfer | transfer.lua | Blind transfer (no announcement) |
| **108** | Attended Transfer | transfer.lua | Attended transfer (with announcement) |
| **111** | API Call | api.lua | Execute HTTP API request (GET/POST) |
| **112** | API POST | api.lua | Simple POST API call |
| **120** | Conditional Logic | logic.lua | Branch based on conditions |
| **200** | Terminate Call | termination.lua | End the call |
| **222** | API Auth | api.lua | Authentication API call |
| **330** | Text-to-Speech | tts.lua | Convert text to speech and play |
| **331** | TTS + Input | tts.lua | TTS with input collection |
| **341** | Record Options | recording.lua | Record with advanced options |

---

## Core Modules

### 1. **`core/init.lua`**
**Purpose**: Core module initializer that coordinates all core components.

**Functions:**
- `initialize(session)` - Initializes the entire core system
- Returns success/error status

**What it does:**
- Initializes session manager with FreeSWITCH session
- Sets up call flow engine
- Prepares operation dispatcher
- Validates core components

---

### 2. **`core/session_manager.lua`**
**Purpose**: Manages call session state and variables throughout the IVR flow.

**Key Features:**
- Session variable management with caching
- Call context tracking (UUID, caller info, timestamps)
- Type-safe variable get/set operations
- Automatic logging of variable changes

**Main Functions:**
```lua
session_manager.initialize(session)              -- Initialize with FS session
session_manager.get_variable(name, default)      -- Get session variable
session_manager.set_variable(name, value)        -- Set session variable
session_manager.get_context()                    -- Get call context info
session_manager.is_ready()                       -- Check if session ready
session_manager.get_caller_id()                  -- Get caller phone number
```

**Example Usage:**
```lua
local caller_id = session_manager.get_caller_id()
session_manager.set_variable("customer_id", "12345")
local customer_id = session_manager.get_variable("customer_id")
```

---

### 3. **`core/call_flow.lua`**
**Purpose**: Orchestrates the IVR call flow by managing node transitions and execution.

**Key Features:**
- Finds and executes start node
- Main processing loop
- Node transition logic
- Error handling and retry logic
- Timeout handling

**Main Functions:**
```lua
call_flow.start()                    -- Start call flow from IsStartNode
call_flow.goto_node(node_id)         -- Jump to specific node
call_flow.handle_agent_callback()    -- Handle agent callback scenario
```

**What it does:**
1. Loads IVRProcessFlow from config
2. Finds start node (IsStartNode = true)
3. Answers the call
4. Enters main loop:
   - Execute current node operation
   - Determine next node based on result
   - Handle repeats and timeouts
   - Move to next node
5. Continues until termination node or hangup

---

### 4. **`core/operation_dispatcher.lua`**
**Purpose**: Routes operation codes to their corresponding handler modules.

**Key Features:**
- Lazy loading of operation modules (performance optimization)
- Operation statistics tracking
- Error handling and logging
- Support for custom operation registration

**Main Functions:**
```lua
dispatcher.execute(operation_code, node_data)      -- Execute operation
dispatcher.register_operation(code, module_name)   -- Add custom operation
dispatcher.get_statistics()                        -- Get execution stats
dispatcher.is_operation_supported(code)            -- Check if op exists
```

**How it works:**
```
Operation Code → Dispatcher → Operation Module → Execution
    (e.g., 30)      ↓            (audio.lua)         ↓
                  Map to                         Play audio
                  "audio"                        Collect input
```

---

## Operation Modules

### 1. **`operations/audio.lua`**
**Handles**: Operations 10, 11, 30, 31, 50

**What it does:**
- **Operation 10**: Play pre-recorded audio file
- **Operation 11**: Play previously recorded file from session
- **Operation 30**: Play audio then collect DTMF input
- **Operation 31**: Play menu options and get selection
- **Operation 50**: Play number sequence using TTS

**Features:**
- Multi-language audio file support
- Repeat logic with configurable limits
- Invalid input handling
- Timeout handling
- Barge-in support (interrupt audio with DTMF)

**Example Node:**
```json
{
  "NodeId": 1001,
  "OperationCode": 10,
  "VoiceFileId": "welcome.wav",
  "RepeatLimit": 0
}
```

---

### 2. **`operations/input.lua`**
**Handles**: Operations 20, 105

**What it does:**
- **Operation 20**: Collect single or multi-character DTMF input
- **Operation 105**: Collect multi-digit input with validation

**Features:**
- Configurable input length
- Valid key validation
- Timeout handling
- Input storage to session variable (TagName)
- Retry logic for invalid input

**Example Node:**
```json
{
  "NodeId": 1002,
  "OperationCode": 20,
  "ValidKeys": "1,2,3",
  "InputLength": 1,
  "InputTimeLimit": 10,
  "TagName": "MenuSelection",
  "InvalidInputVoiceFileId": "invalid.wav",
  "RepeatLimit": 3
}
```

---

### 3. **`operations/recording.lua`**
**Handles**: Operations 40, 341

**What it does:**
- **Operation 40**: Record caller's voice message
- **Operation 341**: Record with advanced options (max length, silence detection)

**Features:**
- Configurable max recording length
- Silence detection and timeout
- Beep before recording
- Save to file system
- Store file path in session variable

**Example Node:**
```json
{
  "NodeId": 2010,
  "OperationCode": 40,
  "RecordingTypeId": 1,
  "TagName": "RecordingFilePath",
  "InputTimeLimit": 120
}
```

---

### 4. **`operations/transfer.lua`**
**Handles**: Operations 100, 101, 107, 108

**What it does:**
- **Operation 100**: Transfer to specific extension
- **Operation 101**: Transfer to call center queue
- **Operation 107**: Blind transfer (no announcement)
- **Operation 108**: Attended transfer (with announcement)

**Features:**
- Extension validation
- Queue management
- Transfer status tracking
- Post-transfer call handling (voicemail, callback)

---

### 5. **`operations/api.lua`**
**Handles**: Operations 111, 112, 222

**What it does:**
- **Operation 111**: Execute HTTP API call (GET/POST)
- **Operation 112**: Simple API POST request
- **Operation 222**: Authentication API call

**Features:**
- Dynamic variable substitution ({{variable_name}})
- Multiple input types (Headers, Body, URL params, Files)
- Response parsing and field extraction
- Session variable population from response
- Success/failure validation
- Integration with http_client service

**How API Calls Work:**

1. **Load API Config**: Get API config from automax_webAPIConfig.json using APIId
2. **Prepare Request**:
   - Replace {{variables}} with session values
   - Build headers, body, URL parameters
   - Handle file attachments
3. **Execute Request**: Use http_client service to make HTTP call
4. **Parse Response**:
   - Extract fields defined in apiOutput
   - Store in session variables (ResultFieldTag)
   - Validate success using IsSuccessValidator
5. **Route Next Node**: Based on success/failure

**Example:**
```json
{
  "NodeId": 3001,
  "OperationCode": 111,
  "APIId": 10
}
```

---

### 6. **`operations/logic.lua`**
**Handles**: Operation 120

**What it does:**
- Conditional branching based on session variables
- Supports multiple comparison operators
- Route to different child nodes based on conditions

**Comparison Operators:**
- Equal, Not Equal
- Greater Than, Less Than
- Contains, StartsWith, EndsWith
- IsEmpty, IsNotEmpty

**Example Node:**
```json
{
  "NodeId": 4001,
  "OperationCode": 120,
  "ChildNodeConfig": [
    {
      "ChildNodeId": 4002,
      "ApplyComparison": true,
      "OperandType": "D",
      "CollectionTag": "CustomerType",
      "ComparisonOperator": "EQ",
      "Value1": "Premium"
    }
  ]
}
```

---

### 7. **`operations/tts.lua`**
**Handles**: Operations 330, 331

**What it does:**
- **Operation 330**: Convert text to speech and play
- **Operation 331**: TTS with subsequent input collection

**Features:**
- Multi-language support (Azure TTS)
- Dynamic text from session variables
- Voice selection per language
- Integration with TTS API (APIId 19)

---

### 8. **`operations/termination.lua`**
**Handles**: Operation 200

**What it does:**
- Gracefully terminate the call
- Play goodbye message
- Clean up resources
- Log call statistics

---

## Service Modules

### 1. **`services/http_client.lua`**
**Purpose**: HTTP request handler with retry logic and error handling.

**Features:**
- GET, POST, PUT, DELETE methods
- Multipart form-data support
- File uploads
- Custom headers
- Timeout handling
- Retry with exponential backoff

---

### 2. **`services/auth_service.lua`**
**Purpose**: Authentication and token management.

**Features:**
- API authentication (Bearer tokens)
- Token caching
- Auto-refresh on expiry
- Session token storage

---

### 3. **`services/incident_service.lua`**
**Purpose**: Incident/ticket creation and management.

**Features:**
- Create incidents from IVR calls
- Attach recordings to incidents
- Update incident status
- Multi-language support (AR/EN)

---

### 4. **`services/attachment_service.lua`**
**Purpose**: File attachment handling for incidents.

**Features:**
- Upload audio recordings
- Multipart form-data encoding
- Attachment validation
- Error handling

---

### 5. **`services/cache_manager.lua`**
**Purpose**: In-memory caching layer.

**Features:**
- TTL-based caching
- Key-value storage
- Automatic expiration
- Cache statistics

---

## Utility Modules

### 1. **`utils/logging.lua`**
**Purpose**: Logging framework with multiple levels.

**Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL

**Functions:**
```lua
local logger = logging.get_logger("module_name")
logger:info("Message")
logger:error("Error message")
logger:debug("Debug info")
```

---

### 2. **`utils/json_utils.lua`**
**Purpose**: JSON parsing and encoding.

**Functions:**
```lua
json_utils.encode(table)           -- Lua table → JSON string
json_utils.decode(json_string)     -- JSON string → Lua table
json_utils.load_file(path)         -- Load JSON from file
json_utils.save_file(path, data)   -- Save Lua table as JSON
```

---

### 3. **`utils/string_utils.lua`**
**Purpose**: String manipulation utilities.

**Functions:**
```lua
string_utils.trim(str)                    -- Remove whitespace
string_utils.split(str, delimiter)        -- Split string
string_utils.replace(str, old, new)       -- Replace substring
string_utils.starts_with(str, prefix)     -- Check prefix
string_utils.interpolate(template, vars)  -- Replace {{var}}
```

---

### 4. **`utils/file_utils.lua`**
**Purpose**: File system operations.

**Functions:**
```lua
file_utils.exists(path)              -- Check if file exists
file_utils.read(path)                -- Read file content
file_utils.write(path, content)      -- Write to file
file_utils.get_mtime(path)           -- Get modification time
file_utils.is_modified(path, mtime)  -- Check if modified since
```

---

### 5. **`utils/validators.lua`**
**Purpose**: Input validation functions.

**Functions:**
```lua
validators.is_valid_phone(number)     -- Validate phone number
validators.is_valid_email(email)      -- Validate email
validators.is_numeric(str)            -- Check if numeric
validators.is_in_range(val, min, max) -- Range validation
```

---

## Examples

### Example 1: Simple Welcome and Language Selection Flow

**ivrconfig.json excerpt:**
```json
{
  "IVRProcessFlow": [
    {
      "NodeId": 1001,
      "NodeName": "Welcome Message",
      "OperationCode": 10,
      "VoiceFileId": "welcome.wav",
      "IsStartNode": true,
      "ChildNodeConfig": [
        {"ChildNodeId": 1002}
      ],
      "RepeatLimit": 0
    },
    {
      "NodeId": 1002,
      "NodeName": "Language Selection",
      "OperationCode": 30,
      "VoiceFileId": "languageoption.wav",
      "IsStartNode": false,
      "ValidKeys": "1,2",
      "InputTimeLimit": 10,
      "TagName": "LanguageSelected",
      "IsLanguageSelect": true,
      "ChildNodeConfig": [
        {
          "ChildNodeId": 1008,
          "InputKeys": "1"
        },
        {
          "ChildNodeId": 1009,
          "InputKeys": "2"
        },
        {
          "ChildNodeId": 1003,
          "InputKeys": "X"
        }
      ],
      "RepeatLimit": 3,
      "InvalidInputVoiceFileId": "com_invalidoption.wav"
    },
    {
      "NodeId": 1003,
      "NodeName": "Max Repeat Reached",
      "OperationCode": 10,
      "VoiceFileId": "com_maxrepeatreached.wav",
      "ChildNodeConfig": [
        {"ChildNodeId": 1004}
      ]
    },
    {
      "NodeId": 1004,
      "NodeName": "Terminate Call",
      "OperationCode": 200
    }
  ]
}
```

**Flow:**
1. Call arrives → Node 1001 plays welcome.wav
2. Automatically moves to Node 1002
3. Node 1002 plays languageoption.wav and waits for DTMF
4. If user presses "1" → Go to Node 1008 (English flow)
5. If user presses "2" → Go to Node 1009 (Arabic flow)
6. If invalid input or timeout → Go to Node 1003
7. After 3 invalid attempts → Play max repeat message → Terminate

---

### Example 2: Authentication API Call

**automax_webAPIConfig.json excerpt:**
```json
{
  "apiId": 10,
  "apiDescription": "Authentication API",
  "apiType": 1,
  "serviceURL": "https://ax3.automaxsw.com/api/v1/auth/login",
  "methodType": "POST",
  "securityMode": "N",
  "inputMediaType": "application/json",
  "apiInput": [
    {
      "FieldName": "email",
      "InputType": "R",
      "InputValueType": "S",
      "InputDataType": "S",
      "InputValue": "admin@automax.com"
    },
    {
      "FieldName": "password",
      "InputType": "R",
      "InputValueType": "S",
      "InputDataType": "S",
      "InputValue": "admin123"
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
  "successMessageText": "Authentication is Success",
  "failureMessageText": "Authentication is Failed"
}
```

**ivrconfig.json excerpt:**
```json
{
  "NodeId": 2001,
  "NodeName": "Authenticate",
  "OperationCode": 111,
  "APIId": 10,
  "ChildNodeConfig": [
    {
      "ChildNodeId": 2002,
      "InputKeys": "S"
    },
    {
      "ChildNodeId": 2003,
      "InputKeys": "F"
    }
  ]
}
```

**How it works:**
1. Node 2001 executes Operation 111 with APIId 10
2. System finds API config (apiId: 10) in automax_webAPIConfig.json
3. Makes POST request to https://ax3.automaxsw.com/api/v1/auth/login
4. Sends JSON body: `{"email": "admin@automax.com", "password": "admin123"}`
5. Receives response: `{"success": true, "data": {"token": "abc123..."}}`
6. Extracts fields:
   - `Access_token` = "abc123..." (from data.token)
   - `success_response` = "true" (from success)
7. Validates success: `success_response` == "true" → Success!
8. Routes to Node 2002 (ChildNode with InputKeys "S" = Success)

---

### Example 3: Create Incident with Recording

**automax_webAPIConfig.json excerpt:**
```json
{
  "apiId": 12,
  "apiDescription": "Create Incident API - EN",
  "serviceURL": "https://ax3.automaxsw.com/api/v1/incidents",
  "methodType": "POST",
  "securityMode": "A",
  "inputMediaType": "application/json",
  "apiInput": {
    "values": [
      {
        "name": "Authorization",
        "value": "Bearer {{Access_token}}",
        "InputType": "H",
        "InputValueType": "D"
      },
      {
        "name": "title",
        "value": "{{IncidentTitleTextEn}}",
        "InputType": "R",
        "InputValueType": "D"
      },
      {
        "name": "description",
        "value": "{{IncidentDetailsTextEn}}",
        "InputType": "R",
        "InputValueType": "D",
        "DefaultValue": "Incident reported via IVR"
      },
      {
        "name": "priority",
        "value": "3",
        "InputType": "R",
        "InputValueType": "S"
      }
    ]
  },
  "apiOutput": [
    {
      "ResultFieldTag": "incident_no_response",
      "ResultFieldName": "id",
      "ParentResultId": "data"
    },
    {
      "ResultFieldTag": "success_response",
      "ResultFieldName": "success",
      "IsSuccessValidator": true,
      "SuccessValue": "true"
    }
  ]
},
{
  "apiId": 23,
  "apiDescription": "Upload Incident Attachment",
  "serviceURL": "https://ax3.automaxsw.com/api/v1/incidents/{incident_id}/attachments",
  "methodType": "POST",
  "securityMode": "A",
  "inputMediaType": "multipart/form-data",
  "apiInput": [
    {
      "FieldName": "incident_id",
      "InputType": "U",
      "InputValueType": "D",
      "InputValue": "incident_no_response"
    },
    {
      "FieldName": "file",
      "InputType": "F",
      "InputValueType": "D",
      "InputValue": "recording_file_path"
    },
    {
      "FieldName": "Authorization",
      "InputType": "H",
      "InputValueType": "D",
      "InputValue": "Bearer {{Access_token}}"
    }
  ]
}
```

**ivrconfig.json excerpt:**
```json
[
  {
    "NodeId": 3001,
    "NodeName": "Record Incident Details",
    "OperationCode": 40,
    "RecordingTypeId": 1,
    "TagName": "recording_file_path",
    "InputTimeLimit": 120,
    "ChildNodeConfig": [
      {"ChildNodeId": 3002}
    ]
  },
  {
    "NodeId": 3002,
    "NodeName": "Create Incident",
    "OperationCode": 111,
    "APIId": 12,
    "ChildNodeConfig": [
      {"ChildNodeId": 3003, "InputKeys": "S"}
    ]
  },
  {
    "NodeId": 3003,
    "NodeName": "Upload Recording",
    "OperationCode": 111,
    "APIId": 23,
    "ChildNodeConfig": [
      {"ChildNodeId": 3004}
    ]
  }
]
```

**Flow:**
1. **Node 3001**: Record caller's description (up to 120 seconds)
   - Saves to file (e.g., `/tmp/recording_123.wav`)
   - Stores path in session variable: `recording_file_path`
2. **Node 3002**: Create incident (API 12)
   - Replaces `{{Access_token}}` with auth token from previous login
   - Replaces `{{IncidentTitleTextEn}}` and `{{IncidentDetailsTextEn}}` with collected data
   - Makes POST to create incident
   - Receives response with incident ID → Stores in `incident_no_response`
3. **Node 3003**: Upload recording (API 23)
   - Replaces `{incident_id}` in URL with `incident_no_response`
   - Uploads file from `recording_file_path`
   - Uses multipart/form-data encoding
4. Success → Play confirmation → End call

---

### Example 4: Conditional Logic Based on Customer Type

**ivrconfig.json excerpt:**
```json
{
  "NodeId": 4001,
  "NodeName": "Check Customer Type",
  "OperationCode": 120,
  "ChildNodeConfig": [
    {
      "ChildNodeId": 4010,
      "ApplyComparison": true,
      "OperandType": "D",
      "CollectionTag": "CustomerType",
      "ComparisonOperator": "EQ",
      "Value1": "Premium"
    },
    {
      "ChildNodeId": 4020,
      "ApplyComparison": true,
      "OperandType": "D",
      "CollectionTag": "CustomerType",
      "ComparisonOperator": "EQ",
      "Value1": "Standard"
    },
    {
      "ChildNodeId": 4030,
      "InputKeys": "*"
    }
  ]
}
```

**How it works:**
1. Node 4001 executes Operation 120 (logic)
2. Gets session variable `CustomerType`
3. Evaluates conditions:
   - If `CustomerType` == "Premium" → Go to Node 4010
   - Else if `CustomerType` == "Standard" → Go to Node 4020
   - Else → Go to Node 4030 (default path)

---

### Example 5: Text-to-Speech with Dynamic Content

**automax_webAPIConfig.json excerpt:**
```json
{
  "apiId": 19,
  "apiDescription": "Text To Speech API",
  "serviceURL": "https://uksouth.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1",
  "methodType": "POST",
  "apiInput": [
    {
      "FieldName": "Language_Code",
      "InputType": "U",
      "InputValueType": "E",
      "InputValue": "TTSLanguageCode"
    },
    {
      "FieldName": "Ocp-Apim-Subscription-Key",
      "InputType": "H",
      "InputValueType": "S",
      "InputValue": "1cfc10bab7f54e53bb5fad1b6d6dfee4"
    },
    {
      "FieldName": "tts_voice",
      "InputType": "H",
      "InputValueType": "E",
      "InputValue": "TTSVoiceNameCloud"
    },
    {
      "FieldName": "TextData",
      "InputType": "R",
      "InputValueType": "E",
      "InputValue": "DefultInput"
    }
  ],
  "apiOutput": [
    {
      "ResultFieldTag": "ttsaudio_response",
      "ResultFieldName": "tts_audio"
    }
  ]
}
```

**ivrconfig.json excerpt:**
```json
{
  "NodeId": 5001,
  "NodeName": "Speak Customer Name",
  "OperationCode": 330,
  "APIId": 19,
  "TagName": "WelcomeMessage",
  "DeafultInput": "Welcome {{CustomerName}}, your account balance is {{AccountBalance}} dollars",
  "ChildNodeConfig": [
    {"ChildNodeId": 5002}
  ]
}
```

**How it works:**
1. Node 5001 executes Operation 330 (TTS)
2. Loads TTS text from `DeafultInput` field
3. Replaces `{{CustomerName}}` and `{{AccountBalance}}` with session variables
4. Final text: "Welcome John Smith, your account balance is 1500 dollars"
5. Calls Azure TTS API (apiId 19) with text
6. Receives audio data
7. Plays audio to caller
8. Moves to Node 5002

---

## Key Concepts

### 1. **Variable Substitution**
Throughout the system, you can use `{{variable_name}}` syntax to reference session variables:
- In API requests: `"Bearer {{Access_token}}"`
- In TTS text: `"Hello {{CallerName}}"`
- In conditional logic: Compare against `{{CustomerType}}`

### 2. **Node Routing**
Every node has a `ChildNodeConfig` array that defines possible next nodes:
- `InputKeys`: What input leads to this child
  - Specific digit: "1", "2", etc.
  - "X" = Invalid input
  - "T" = Timeout
  - "S" = Success (API calls)
  - "F" = Failure (API calls)
  - "*" = Default/catch-all
- `ApplyComparison`: Use conditional logic instead of input matching

### 3. **Repeat and Timeout Logic**
- `RepeatLimit`: Max times to repeat the node (e.g., for invalid input)
- `InputTimeLimit`: Seconds to wait for user input
- `InvalidInputVoiceFileId`: Audio to play on invalid input
- `TimeLimitResponseType`: What to do on timeout

### 4. **Session Variables**
- `TagName`: Store operation result in this session variable
- Retrieved with `session_manager.get_variable()`
- Used across the entire call flow
- Persist for the duration of the call

### 5. **Multi-Language Support**
- `IsLanguageSelect`: Mark node as language selector
- `LanguageList` in GeneralSettings defines available languages
- Audio files organized by language
- API responses can be language-specific

---

## Configuration Best Practices

### ivrconfig.json
1. **Node IDs**: Use sequential IDs (1001, 1002, etc.) for readability
2. **Start Node**: Always have exactly one node with `IsStartNode: true`
3. **Error Handling**: Always include "X" and "T" paths in ChildNodeConfig
4. **Validation**: Use `ValidKeys` to restrict input
5. **Timeouts**: Set reasonable `InputTimeLimit` values (5-10 seconds for menus)
6. **Repeat Limits**: Prevent infinite loops with `RepeatLimit` (typically 3-5)

### automax_webAPIConfig.json
1. **API IDs**: Use unique IDs for each API
2. **Security**: Use `securityMode: "A"` for authenticated APIs
3. **Validation**: Always include success validator in apiOutput
4. **Defaults**: Provide `DefaultValue` for optional fields
5. **Error Messages**: Define clear `successMessageText` and `failureMessageText`

---

## Troubleshooting

### Common Issues

**Issue**: Call flow not starting
- **Check**: IsStartNode set to true on initial node
- **Check**: ivrconfig.json loaded successfully (check logs)

**Issue**: API calls failing
- **Check**: Authentication token valid (apiId 10)
- **Check**: Variable names in {{}} match session variables
- **Check**: API endpoint URL accessible

**Issue**: Audio not playing
- **Check**: VoiceFileId matches actual file name
- **Check**: Audio files in correct directory
- **Check**: File format compatible with FreeSWITCH (WAV recommended)

**Issue**: Input not collected
- **Check**: ValidKeys configured correctly
- **Check**: InputTimeLimit not too short
- **Check**: DTMF detection enabled on trunk

---

## Summary

This IVR system provides a powerful, flexible framework for building complex telephony applications:

- **Configuration-Driven**: Modify call flows without code changes
- **Modular Architecture**: Clean separation of concerns
- **Extensible**: Easy to add new operations and integrations
- **Multi-Language**: Built-in support for multiple languages
- **API Integration**: Connect to external systems (CRM, ticketing, etc.)
- **Error Handling**: Robust retry and timeout mechanisms
- **Logging**: Comprehensive logging for debugging and monitoring

The two main configuration files (`ivrconfig.json` and `automax_webAPIConfig.json`) control all behavior, making it easy to customize and maintain the IVR system without touching the Lua code.

---

**Last Updated**: 2026-02-04
**Version**: 2.0.0
**Maintainer**: IVR System Team
