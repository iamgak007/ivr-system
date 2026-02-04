# Modular IVR System for FreeSWITCH

## Overview

This is a completely refactored, modular IVR (Interactive Voice Response) system for FreeSWITCH. The original monolithic script (~2150 lines) has been broken down into manageable, well-documented modules organized by functionality.

## 📚 Documentation

This project includes comprehensive documentation to help you understand and work with the IVR system:

- **[DOCUMENTATION.md](./DOCUMENTATION.md)** - Complete system documentation including:
  - Detailed explanation of all files and directories
  - Configuration file structure and examples
  - Module descriptions and functions
  - Complete guide to `ivrconfig.json` and `automax_webAPIConfig.json`
  - Real-world examples and use cases

- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick reference guide with:
  - Configuration syntax cheat sheets
  - Operation code reference table
  - Common patterns and templates
  - Debugging tips
  - Session variable reference

- **[CALL_FLOW_DIAGRAMS.md](./CALL_FLOW_DIAGRAMS.md)** - Visual flow diagrams showing:
  - System architecture
  - Complete call flow timeline
  - Node processing patterns
  - Error handling flows
  - Multi-language flow examples

- **[CONFIG_EXAMPLES.md](./CONFIG_EXAMPLES.md)** - Ready-to-use configuration examples:
  - Simple welcome flows
  - Multi-level menus
  - Language selection
  - Customer ID collection
  - Recording messages
  - API integration
  - Incident creation
  - Call transfers
  - And more...

**👉 Start with [DOCUMENTATION.md](./DOCUMENTATION.md) for a complete understanding of the system.**

## Architecture

### Directory Structure

```
/usr/local/freeswitch/scripts/ivr-system/
├── main.lua                          # Main entry point
├── config/
│   └── init.lua                      # Configuration loader with caching
├── core/
│   ├── init.lua                      # Core system initialization
│   ├── session_manager.lua           # Session variable management
│   ├── call_flow.lua                 # Call flow routing logic
│   └── operation_dispatcher.lua      # Operation code dispatcher
├── operations/
│   ├── audio.lua                     # Audio operations (10,11,30,31,50)
│   ├── input.lua                     # Input operations (20,105)
│   ├── recording.lua                 # Recording operations (40,341)
│   ├── transfer.lua                  # Transfer operations (100,101,107,108)
│   ├── api.lua                       # API operations (111,112)
│   ├── logic.lua                     # Logic operations (120)
│   ├── tts.lua                       # Text-to-speech (330,331)
│   └── termination.lua               # Call termination (200)
├── services/
│   ├── init.lua                      # Services initialization
│   ├── http_client.lua               # HTTP client with connection pooling
│   ├── cache_manager.lua             # Caching layer
│   ├── attachment_service.lua        # File upload/attachment handling
│   ├── incident_service.lua          # Incident creation/management
│   └── auth_service.lua              # Authentication token management
└── utils/
    ├── init.lua                      # Utilities loader
    ├── string_utils.lua              # String manipulation, escaping
    ├── json_utils.lua                # JSON processing utilities
    ├── file_utils.lua                # File operations
    ├── logging.lua                   # Smart logging system
    └── validators.lua                # Input validation

/usr/local/freeswitch/scripts/ivr-cc-config/
├── ivrconfig.json                    # IVR flow configuration
├── automax_webAPIConfig.json         # API endpoints configuration
├── Extensions_qa.json                # Agent extensions
└── RecordingType_qa.json            # Recording configurations
```

## Key Features

### 1. Modular Design
- **Separation of Concerns**: Each module handles a specific responsibility
- **Lazy Loading**: Modules are loaded only when needed for performance
- **Reusability**: Services and utilities can be shared across operations
- **Testability**: Individual modules can be unit tested

### 2. Configuration Management
- **Hot Reloading**: Detects file changes without service restart
- **Caching**: In-memory caching with modification time tracking
- **Validation**: Automatic validation of configuration structure
- **Multiple Configs**: Supports IVR flows, API configs, extensions, etc.

### 3. Comprehensive Logging
- **Multiple Levels**: DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL
- **Module-Specific**: Each module has its own logger with prefixes
- **Structured Logging**: Support for logging complex data structures
- **FreeSWITCH Integration**: Integrates with FreeSWITCH console logging

### 4. Error Handling
- **Graceful Degradation**: Errors are caught and logged appropriately
- **Session Protection**: Prevents hanging sessions on errors
- **Retry Logic**: Built-in retry mechanisms for operations
- **Error Recovery**: Attempts to recover from non-critical errors

### 5. Security
- **Input Validation**: All user inputs are validated and sanitized
- **Shell Escaping**: Proper escaping for shell commands
- **SQL Escaping**: Protection against SQL injection
- **URL Encoding**: Safe handling of URL parameters

## Module Descriptions

### Core Modules

#### `main.lua`
- Entry point for the IVR system
- Initializes all subsystems
- Handles top-level error catching
- Orchestrates call flow startup

#### `core/init.lua`
- Coordinates core system initialization
- Manages system lifecycle
- Provides unified interface to core components

#### `core/session_manager.lua`
- Manages FreeSWITCH session state
- Handles session variables with caching
- Provides typed variable access
- Tracks call context information

#### `core/call_flow.lua`
- Controls IVR navigation flow
- Finds and executes nodes
- Handles parent/child relationships
- Manages DTMF routing
- Prevents infinite loops

#### `core/operation_dispatcher.lua`
- Routes operation codes to handlers
- Implements lazy loading of operations
- Tracks operation statistics
- Provides operation registration API

### Operation Modules

Operation modules implement the actual IVR functionality. Each operation module:
- Validates input data
- Performs the specific operation
- Handles errors gracefully
- Navigates to next node

**Operation Code Mapping:**
- **10, 11, 30, 31, 50**: Audio playback operations
- **20, 105**: Input collection operations
- **40, 341**: Recording operations
- **100, 101, 107, 108**: Transfer operations
- **111, 112**: API integration operations
- **120**: Logic/conditional operations
- **200**: Call termination
- **330, 331**: Text-to-speech operations

### Service Modules

Services provide cross-cutting functionality used by multiple operations:

#### `services/http_client.lua`
- HTTP/HTTPS requests using curl
- Response parsing and error handling
- Optional caching of responses
- Support for various HTTP methods

#### `services/cache_manager.lua`
- In-memory caching layer
- TTL (Time To Live) support
- Cache invalidation mechanisms
- Performance optimization

#### `services/attachment_service.lua`
- File upload functionality
- Attachment validation
- Integration with external systems

#### `services/incident_service.lua`
- Incident creation and management
- Integration with ticketing systems
- Error reporting

#### `services/auth_service.lua`
- Authentication token management
- Token refresh logic
- Secure credential handling

### Utility Modules

Utilities provide common functionality across the system:

#### `utils/logging.lua`
- Multiple log levels
- Module-specific loggers
- Structured data logging
- Integration with FreeSWITCH

#### `utils/string_utils.lua`
- Shell command escaping (CRITICAL for security)
- String manipulation
- URL encoding/decoding
- SQL escaping

#### `utils/json_utils.lua`
- JSON parsing with error handling
- JSON encoding
- File I/O for JSON
- Deep copy functionality

#### `utils/file_utils.lua`
- File existence checks
- File size validation
- Modification time tracking
- Directory operations

#### `utils/validators.lua`
- Phone number validation
- Email validation
- DTMF validation
- Numeric range validation
- URL validation
- Input sanitization

## Usage Examples

### Basic Usage

```lua
-- In FreeSWITCH dialplan, call the main script
<action application="lua" data="ivr-system/main.lua"/>
```

### Using Individual Modules

```lua
-- Load the config module
local config = require "config"

-- Load all configurations
config.load_all()

-- Get specific configuration
local ivr_flow = config.get_ivr_flow()
local webapi_endpoints = config.get_webapi_endpoints()
```

```lua
-- Use logging
local logging = require "utils.logging"
local logger = logging.get_logger("my_module")

logger:info("Processing started")
logger:debug("Debug information: " .. data)
logger:error("An error occurred")
```

```lua
-- Use session manager
local session_manager = require "core.session_manager"

-- Set a variable
session_manager.set_variable("customer_id", "12345")

-- Get a variable
local customer_id = session_manager.get_variable("customer_id")

-- Get call context
local context = session_manager.get_context()
print(context.call_uuid)
print(context.caller_id)
```

```lua
-- Use validators
local validators = require "utils.validators"

if validators.is_valid_phone(user_input) then
    -- Process phone number
end

if validators.is_valid_dtmf(input, 1, 5) then
    -- Process DTMF input
end
```

## Creating New Operations

To create a new operation module:

1. Create a new file in `operations/` directory
2. Follow the standard module pattern:

```lua
local M = {}

-- Load dependencies
local session_manager = require "core.session_manager"
local call_flow = require "core.call_flow"
local logging = require "utils.logging"

local logger = logging.get_logger("operations.your_operation")

function M.execute(operation_code, node_data)
    logger:info("Executing operation " .. operation_code)
    
    -- Validate inputs
    if not node_data.RequiredField then
        logger:error("Missing required field")
        return
    end
    
    -- Perform operation
    -- ...
    
    -- Navigate to next node
    call_flow.find_child_node(node_data)
end

return M
```

3. Register the operation in `core/operation_dispatcher.lua`:

```lua
local operation_map = {
    [your_code] = "your_operation",
    -- ... other operations
}
```

## Configuration Hot Reloading

The system detects configuration file changes automatically:

```lua
-- Force reload a specific configuration
local config = require "config"
config.reload("ivr")
```

## Error Handling Best Practices

1. **Always validate inputs**
```lua
if not node_data or not node_data.NodeId then
    logger:error("Invalid node data")
    return
end
```

2. **Use pcall for risky operations**
```lua
local success, result = pcall(function()
    -- Risky operation
end)

if not success then
    logger:error("Operation failed: " .. tostring(result))
end
```

3. **Gracefully handle session errors**
```lua
if not session or not session:ready() then
    logger:error("Session not ready")
    return
end
```

## Performance Considerations

### Lazy Loading
Modules are loaded only when first used:
```lua
-- Module is not loaded until first access
local audio = require "operations.audio"
```

### Caching
Configuration files are cached in memory:
```lua
-- Only reloads if file has been modified
config.load_all()
```

### Session Variable Caching
Session variables are cached to reduce FreeSWITCH calls:
```lua
-- First call queries FreeSWITCH
local value1 = session_manager.get_variable("var")

-- Subsequent calls use cache
local value2 = session_manager.get_variable("var")
```

## Security Features

### Input Sanitization
```lua
local string_utils = require "utils.string_utils"

-- CRITICAL: Always escape user input before shell commands
local safe_input = string_utils.shell_escape(user_input)
local cmd = "curl " .. safe_url .. " -d " .. safe_input
```

### Validation
```lua
local validators = require "utils.validators"

-- Validate before processing
if not validators.is_valid_phone(phone) then
    logger:error("Invalid phone number")
    return
end
```

## Migration from Monolithic Script

To migrate from the original monolithic script:

1. **Update FreeSWITCH dialplan** to call the new main.lua
2. **No configuration changes needed** - same JSON files are used
3. **Test thoroughly** - especially operation codes used in your IVR flow
4. **Monitor logs** - check for any errors or warnings
5. **Gradually extend** - add new operations as needed

## Benefits Over Monolithic Design

1. **Maintainability**: ~100-200 lines per file vs. 2000+ lines
2. **Debugging**: Easier to locate and fix issues
3. **Testing**: Can unit test individual modules
4. **Extensibility**: Easy to add new operations
5. **Reusability**: Services shared across operations
6. **Performance**: Lazy loading and caching
7. **Code Quality**: Better documentation and structure
8. **Team Collaboration**: Multiple developers can work on different modules

## Implementation Status

All modules documented in this README are now implemented:

### Operation Modules (Complete)
| Module | Operations | Status |
|--------|-----------|--------|
| `operations/audio.lua` | 10, 11, 30, 31, 50 | ✅ Implemented |
| `operations/input.lua` | 20, 105 | ✅ Implemented |
| `operations/recording.lua` | 40, 341 | ✅ Implemented |
| `operations/transfer.lua` | 100, 101, 107, 108 | ✅ Implemented |
| `operations/api.lua` | 111, 112 | ✅ Implemented |
| `operations/logic.lua` | 120 | ✅ Implemented |
| `operations/tts.lua` | 330, 331 | ✅ Implemented |
| `operations/termination.lua` | 200 | ✅ Implemented |

### Service Modules (Complete)
| Module | Status |
|--------|--------|
| `services/http_client.lua` | ✅ Implemented |
| `services/cache_manager.lua` | ✅ Implemented |
| `services/attachment_service.lua` | ✅ Implemented |
| `services/incident_service.lua` | ✅ Implemented |
| `services/auth_service.lua` | ✅ Implemented |

### Core Modules (Complete)
| Module | Status |
|--------|--------|
| `main.lua` | ✅ Implemented |
| `config/init.lua` | ✅ Implemented |
| `core/init.lua` | ✅ Implemented |
| `core/session_manager.lua` | ✅ Implemented |
| `core/call_flow.lua` | ✅ Implemented |
| `core/operation_dispatcher.lua` | ✅ Implemented |

### Utility Modules (Complete)
| Module | Status |
|--------|--------|
| `utils/logging.lua` | ✅ Implemented |
| `utils/string_utils.lua` | ✅ Implemented |
| `utils/json_utils.lua` | ✅ Implemented |
| `utils/file_utils.lua` | ✅ Implemented |
| `utils/validators.lua` | ✅ Implemented |

## Security Notes

**IMPORTANT**: Before deploying to production, review and update the following:

1. **Azure TTS Credentials**: Configure Azure credentials via FreeSWITCH globals (see Configuration section below).

2. **API Endpoints**: The `services/incident_service.lua` and `services/auth_service.lua` modules require proper API endpoint configuration.

3. **Input Validation**: While the modular system includes input validation, always review and test with your specific use cases.

4. **Shell Command Escaping**: The `utils/string_utils.lua` provides shell escaping functions. Always use these when building commands with user input.

## Required Configuration

### Azure TTS (Operation 331)

Configure Azure credentials in FreeSWITCH `vars.xml` or set as global variables:

```xml
<!-- In vars.xml -->
<X-PRE-PROCESS cmd="set" data="azure_subscription_key=YOUR_AZURE_KEY_HERE"/>
<X-PRE-PROCESS cmd="set" data="azure_region=uksouth"/>
```

Or set at runtime:
```lua
freeswitch.setGlobalVariable("azure_subscription_key", "YOUR_KEY")
freeswitch.setGlobalVariable("azure_region", "uksouth")
```

Session variables can also be used:
- `AZURE_SUBSCRIPTION_KEY` - Azure subscription key
- `AZURE_REGION` - Azure region (default: uksouth)
- `AZURE_TTS_SPEED` - Speech speed (default: 0)

## Configuration Field Names

The modular system supports both field naming conventions from the original implementation:

| Original Field | Alternative Field | Used In |
|---------------|-------------------|---------|
| `InputKeys` | `DTMFInput` | Child node DTMF routing |
| `TagName` | `RecordedFileVariable` | Recording file reference |

The system will check for both field names to maintain compatibility

## Troubleshooting

### Check Logs
```bash
tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i "ivr"
```

### Enable Debug Logging
```lua
local logging = require "utils.logging"
logging.set_level(logging.LEVELS.DEBUG)
```

### Verify Configuration Loading
```lua
local config = require "config"
local success, error = config.load_all()
if not success then
    print("Config error: " .. error)
end
```

### Check File Paths
```lua
local file_utils = require "utils.file_utils"
if not file_utils.exists("/path/to/file") then
    print("File not found")
end
```

## License

Copyright © 2025 IVR System Team

## Support

For issues and questions:
- Check the logs first
- Review module documentation
- Contact the development team
