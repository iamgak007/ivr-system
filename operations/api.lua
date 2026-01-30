--------------------------------------------------------------------------------
-- API Operations Module
--
-- Handles all API integration related operations including:
-- - Operation 111: API call (GET/POST with various content types)
-- - Operation 112: Simple API POST call
--
-- These operations interact with external web services to fetch data,
-- authenticate, create incidents, etc.
--
-- Usage:
--   Called automatically by the operation dispatcher
--   local api_ops = require "operations.api"
--   api_ops.execute(111, node_data)
--
-- Author: IVR System Team
-- Version: 2.0.0
--------------------------------------------------------------------------------
local M = {}

-- Load dependencies
local session_manager = require "core.session_manager"
local call_flow = require "core.call_flow"
local config = require "config"
local logging = require "utils.logging"
local string_utils = require "utils.string_utils"
local json_utils = require "utils.json_utils"
local file_utils = require "utils.file_utils"

-- Module logger
local logger = logging.get_logger("operations.api")

--------------------------------------------------------------------------------
-- Execute API Operation
--
-- Main entry point for all API operations. Routes to specific handlers
-- based on operation code.
--
-- @param operation_code number - The operation code (111, 112)
-- @param node_data table - The IVR node configuration data
-- @return void
--------------------------------------------------------------------------------
function M.execute(operation_code, node_data)
    logger:info(string.format("Executing API operation %d for node %d", operation_code, node_data.NodeId))

    -- Route to appropriate handler
    if operation_code == 111 then
        M.api_call(node_data)
    elseif operation_code == 112 then
        M.api_post(node_data)
    else
        error(string.format("Unknown API operation code: %d", operation_code))
    end
end

--------------------------------------------------------------------------------
-- Helper: URL encode a string
--
-- @param str string - String to encode
-- @return string - URL encoded string
--------------------------------------------------------------------------------
local function urlencode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w _%%%-%.~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

--------------------------------------------------------------------------------
-- Helper: URL encode a table
--
-- @param tbl table - Table of key-value pairs
-- @return string - URL encoded string
--------------------------------------------------------------------------------
local function urlencode_table(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        table.insert(result, urlencode(k) .. "=" .. urlencode(tostring(v)))
    end
    return table.concat(result, "&")
end

--------------------------------------------------------------------------------
-- Helper: Convert table to values format for API
--
-- Transforms a Lua table into the specific JSON format expected by some APIs.
--
-- @param tbl table - Table to convert
-- @return table - Converted table with values array
--------------------------------------------------------------------------------
local function convert_to_values_format(tbl)
    local values_array = {}
    for key, value in pairs(tbl) do
        table.insert(values_array, {
            name = key,
            value = type(value) == "table" and json_utils.encode(value) or tostring(value)
        })
    end
    return {
        values = values_array
    }
end

--------------------------------------------------------------------------------
-- Helper: Replace placeholder in URL
--
-- @param url string - URL with placeholder
-- @param field_name string - Placeholder name (without braces)
-- @param replacement string - Replacement value
-- @return string - URL with placeholder replaced
--------------------------------------------------------------------------------
local function replace_placeholder(url, field_name, replacement)
    return url:gsub(field_name, replacement or "")
end

--------------------------------------------------------------------------------
-- Helper: Fetch data from API
--
-- @param api_url string - API URL
-- @param auth_token string - Bearer token
-- @return table|nil - Decoded response data or nil on failure
--------------------------------------------------------------------------------
local function fetch_api_data(api_url, auth_token)
    local curl_cmd = string.format('curl -s "%s" -H "Authorization: Bearer %s" -H "Content-Type: application/json"',
        api_url, auth_token)
    logger:info("Executing curl: " .. curl_cmd)

    local handle = io.popen(curl_cmd)
    local response = handle:read("*a")
    handle:close()

    logger:debug("Raw API response: " .. (response or "nil"))

    if response and response ~= "" then
        local success, decoded = json_utils.decode(response)
        if success and decoded then
            logger:debug("Response decoded successfully")
            if decoded.data then
                logger:info(string.format("Response contains data field with %d item(s)",
                    type(decoded.data) == "table" and #decoded.data or 0))
                return decoded.data
            else
                logger:warning("Response decoded but no 'data' field found")
            end
        else
            logger:error("Failed to decode JSON response: " .. tostring(decoded))
        end
    else
        logger:error("Empty or nil response from API")
    end
    return nil
end

--------------------------------------------------------------------------------
-- Helper: Get classification ID by index (tree structure)
--
-- Handles hierarchical tree structure from /classifications/tree endpoint:
-- { "data": [{ "id": "parent-uuid", "children": [{ "id": "child-uuid" }] }] }
--
-- @param classifications table - List of parent classifications with children
-- @param class_index number - Main classification index (1-based)
-- @param subclass_index number - Sub-classification index (1-based, optional)
-- @return string|nil - Classification UUID or nil
--------------------------------------------------------------------------------
local function get_classification_id_by_index(classifications, class_index, subclass_index)
    if not classifications or type(classifications) ~= "table" then
        return nil
    end

    -- Get parent classification at index
    local parent = classifications[class_index]
    if not parent then
        logger:warning("Classification index " .. tostring(class_index) .. " not found")
        return nil
    end

    logger:info(string.format("Found parent classification at index %d: %s (%s)", class_index, parent.name or "unnamed",
        parent.id))

    -- If subclass_index provided and parent has children, get child
    if subclass_index and subclass_index > 0 and parent.children and #parent.children > 0 then
        local child = parent.children[subclass_index]
        if child and child.id then
            logger:info(string.format("Mapped classification %d/%d to child: %s (%s)", class_index, subclass_index,
                child.name or "unnamed", child.id))
            return child.id
        else
            logger:warning(string.format("Sub-classification index %d not found in parent %s", subclass_index,
                parent.name or parent.id))
        end
    end

    -- Return parent ID if no subclass or subclass not found
    logger:info("Mapped classification index " .. tostring(class_index) .. " to parent ID: " .. parent.id)
    return parent.id
end

--------------------------------------------------------------------------------
-- Helper: Get location ID by index
--
-- @param locations table - List of locations
-- @param location_index number - Location index (1-based)
-- @return string|nil - Location UUID or nil
--------------------------------------------------------------------------------
local function get_location_id_by_index(locations, location_index)
    if not locations or type(locations) ~= "table" then
        return nil
    end

    local loc = locations[location_index]
    if loc and loc.id then
        logger:info("Mapped location index " .. tostring(location_index) .. " to ID: " .. loc.id)
        return loc.id
    end

    logger:warning("Location index " .. tostring(location_index) .. " not found")
    return nil
end

--------------------------------------------------------------------------------
-- Helper: Map classification and location indices to UUIDs
--
-- Fetches classification and location lists from API and maps
-- stored indices to actual UUIDs for incident creation.
-- If no indices are set, uses the first available option.
--
-- @param session - FreeSWITCH session
-- @return void
--------------------------------------------------------------------------------
local function map_indices_to_uuids(session)
    local access_token = session:getVariable("Access_token")
    if not access_token then
        logger:warning("No access token available for mapping")
        return
    end

    -- Get indices from session
    local class_index = tonumber(session:getVariable("ClassificationIdEn") or session:getVariable("ClassificationIdAr"))
    local subclass_index = tonumber(session:getVariable("SubClassificationIdEn") or
                                        session:getVariable("SubClassificationIdAr"))
    local location_index = tonumber(session:getVariable("LocationIdEn") or session:getVariable("LocationIdAr"))

    logger:info(string.format("Mapping indices - Classification: %s, SubClass: %s, Location: %s", tostring(class_index),
        tostring(subclass_index), tostring(location_index)))

    -- Fetch classifications from tree endpoint (hierarchical structure with children)
    logger:info("Fetching classifications from API: https://ax3.automaxsw.com/api/v1/admin/classifications/tree")
    local classifications = fetch_api_data("https://ax3.automaxsw.com/api/v1/admin/classifications/tree", access_token)
    logger:info(tostring(classifications))
    if classifications then
        logger:info(string.format("Successfully fetched %d classification(s) from /tree endpoint", #classifications))
        local success, json_data = json_utils.encode(classifications)
        if success then
            logger:info("Full classifications data: " .. json_data)
        else
            logger:error("Failed to encode classifications: " .. tostring(json_data))
        end
        -- Log first classification structure for debugging
        if classifications[1] then
            logger:debug(string.format("First classification: id=%s, name=%s, has_children=%s",
                classifications[1].id or "nil", classifications[1].name or "nil",
                (classifications[1].children and #classifications[1].children > 0) and "yes (" ..
                    #classifications[1].children .. ")" or "no"))
        end
        local class_id
        if class_index then
            -- Map index to UUID using tree structure
            logger:info(string.format("Classification index IS SET - mapping index %s (subclass: %s) to UUID",
                tostring(class_index), tostring(subclass_index)))
            class_id = get_classification_id_by_index(classifications, class_index, subclass_index)
            if class_id then
                logger:info("Successfully mapped to UUID: " .. class_id)
            else
                logger:error("Failed to map classification index to UUID")
            end
        else
            -- No index set - use first child from first parent (tree structure)
            logger:info("Classification index NOT SET - using fallback (first available)")
            local first_parent = classifications[1]
            if first_parent then
                logger:debug(string.format("First parent: id=%s, name=%s", first_parent.id or "nil",
                    first_parent.name or "nil"))

                if first_parent.children and #first_parent.children > 0 then
                    -- Use first sub-classification (child) from first parent
                    class_id = first_parent.children[1].id
                    logger:info(string.format("Fallback: Using first sub-classification: %s (%s)",
                        first_parent.children[1].name or "unnamed", class_id))
                else
                    -- Fallback to first parent if no children
                    class_id = first_parent.id
                    logger:info(string.format("Fallback: No children found, using first parent: %s (%s)",
                        first_parent.name or "unnamed", class_id))
                end
            else
                logger:error("Fallback failed: No classifications available in response")
            end
        end

        if class_id then
            session:setVariable("ClassificationIdEn", class_id)
            session:setVariable("ClassificationIdAr", class_id)
            logger:info("==> FINAL: Set ClassificationIdEn/Ar to: " .. class_id)
        else
            logger:error("==> FINAL: No classification ID set (class_id is nil)")
        end
    else
        logger:error("Failed to fetch classifications from /tree endpoint")
    end

    -- Fetch locations
    logger:info("Fetching locations from API: https://ax3.automaxsw.com/api/v1/admin/locations")
    local locations = fetch_api_data("https://ax3.automaxsw.com/api/v1/admin/locations", access_token)

    if locations then
        logger:info(string.format("Successfully fetched %d location(s)", #locations))

        -- Log first location for debugging
        if locations[1] then
            logger:debug(string.format("First location: id=%s, name=%s", locations[1].id or "nil",
                locations[1].name or "nil"))
        end

        local loc_id
        if location_index then
            -- Map index to UUID
            logger:info(string.format("Location index IS SET - mapping index %s to UUID", tostring(location_index)))
            loc_id = get_location_id_by_index(locations, location_index)
            if loc_id then
                logger:info("Successfully mapped to UUID: " .. loc_id)
            else
                logger:error("Failed to map location index to UUID")
            end
        else
            -- No index set - use first location
            logger:info("Location index NOT SET - using fallback (first available)")
            if locations[1] and locations[1].id then
                loc_id = locations[1].id
                logger:info(string.format("Fallback: Using first location: %s (%s)", locations[1].name or "unnamed",
                    loc_id))
            else
                logger:error("Fallback failed: No locations available in response")
            end
        end

        if loc_id then
            session:setVariable("LocationIdEn", loc_id)
            session:setVariable("LocationIdAr", loc_id)
            logger:info("==> FINAL: Set LocationIdEn/Ar to: " .. loc_id)
        else
            logger:error("==> FINAL: No location ID set (loc_id is nil)")
        end
    else
        logger:error("Failed to fetch locations from API")
    end
    
    -- Fetch Workflow
    logger:info("Fetching workflow from API: https://ax3.automaxsw.com/api/v1/admin/workflows?record_type=incident")
    local workflows = fetch_api_data("https://ax3.automaxsw.com/api/v1/admin/workflows?record_type=incident", access_token)
    if workflows then
        logger:info(string.format("Successfully fetched %d workflow(s)", #workflows))

        if workflows[1] and workflows[1].id then
            local workflow_id = workflows[1].id
            session:setVariable("WorkflowIdEn", workflow_id)
            session:setVariable("WorkflowIdAr", workflow_id)
            logger:info("==> FINAL: Set WorkflowIdEn/Ar to: " .. workflow_id)
        else
            logger:error("No workflows available to set WorkflowId")
        end
    else
        logger:error("Failed to fetch workflows from API")
    end
end

--------------------------------------------------------------------------------
-- Helper: Construct API call
--
-- Builds a curl command based on API configuration.
--
-- @param method_type string - HTTP method (GET, POST, etc.)
-- @param content_type string - Content type
-- @param service_url string - Base URL
-- @param api_input_data table - Input configuration
-- @return string - Constructed curl command
--------------------------------------------------------------------------------
local function construct_api(method_type, content_type, service_url, api_input_data)
    local session = session_manager.get_freeswitch_session()
    local payload = {}
    local headers = ""
    local form_data = ""
    local binary_data = ""

    logger:debug("Constructing API call")

    local input_array = api_input_data.headers or api_input_data.values or api_input_data

    for _, item in ipairs(input_array) do
        local input_type = item.InputType

        if input_type == "U" then
            -- URL parameter
            local input_value
            if item.InputValueType == "D" or item.InputValueType == "E" then
                input_value = session:getVariable(item.InputValue)
                service_url = replace_placeholder(service_url, '{' .. item.FieldName .. '}', input_value)
            elseif item.InputValueType == "S" then
                service_url = replace_placeholder(service_url, '{' .. item.FieldName .. '}', item.InputValue)
            end

        elseif input_type == "R" then
            -- Request body parameter
            local key = item.FieldName or item.name
            local val
            local default_value = item.DefaultValue

            if item.InputValueType == "D" or item.InputValueType == "E" then
                local raw_input = item.InputValue or item.value
                local variable_name = tostring(raw_input):match("{{(.-)}}")

                if variable_name then
                    val = session:getVariable(variable_name)
                    logger:debug(string.format("Variable {{%s}} = %s", variable_name, tostring(val)))
                    if val and val ~= "" then
                        val = tostring(val):gsub('^"(.*)"$', '%1')
                        val = tostring(raw_input):gsub("{{" .. variable_name .. "}}", val)
                    elseif default_value then
                        -- Use default value if variable not set
                        val = default_value
                        logger:debug(string.format("Using default value for %s: %s", key, default_value))
                    else
                        val = nil
                    end
                else
                    val = session:getVariable(item.InputValue)
                    if (not val or val == "") and default_value then
                        val = default_value
                    end
                end
            else
                val = item.value or item.InputValue
                if val then
                    if key == "Map" then
                        payload[key] = {
                            coordinates = {0.0, 0.0}
                        }
                    else
                        val = tostring(val):gsub('^"(.*)"$', '%1')
                        payload[key] = val
                    end
                end
            end

            -- Only add to payload if we have a value
            if key and val and val ~= "" and key ~= "Map" then
                payload[key] = val
            elseif key and default_value and key ~= "Map" then
                payload[key] = default_value
            end

        elseif input_type == "B" then
            -- Binary data
            local input_value
            if item.InputValueType == "D" or item.InputValueType == "E" then
                input_value = session:getVariable(item.InputValue)
            else
                input_value = item.InputValue
            end
            binary_data = binary_data .. " --data-binary @" .. input_value

        elseif input_type == "F" then
            -- Form data
            local input_value
            if item.InputValueType == "D" or item.InputValueType == "E" then
                input_value = session:getVariable(item.InputValue)
            elseif item.InputValueType == "S" then
                input_value = item.InputValue
            end

            if input_value and string.find(input_value, "%.wav$") then
                form_data = form_data .. " -F " .. item.FieldName .. "=@" .. input_value
            else
                form_data = form_data .. " -F " .. item.FieldName .. "=" .. (input_value or "")
            end

        elseif input_type == "H" then
            -- Header
            local field_name = item.FieldName or item.name
            local input_value = item.InputValue or item.value

            if item.InputValueType == "D" or item.InputValueType == "E" then
                -- Check for double braces pattern {{variable}}
                local double_brace_var = input_value:match("{{(.-)}}")
                -- Check for single brace pattern {variable}
                local single_brace_var = input_value:match("{(.-)}")

                if double_brace_var then
                    local var_value = session:getVariable(double_brace_var)
                    logger:debug(string.format("Header variable {{%s}} = %s", double_brace_var, tostring(var_value)))
                    if var_value then
                        input_value = input_value:gsub("{{" .. double_brace_var .. "}}", var_value)
                    end
                    headers = headers .. field_name .. ": " .. input_value
                elseif single_brace_var then
                    local var_value = session:getVariable(single_brace_var)
                    logger:debug(string.format("Header variable {%s} = %s", single_brace_var, tostring(var_value)))
                    if var_value then
                        input_value = input_value:gsub("{" .. single_brace_var .. "}", var_value)
                    end
                    headers = headers .. field_name .. ": " .. input_value
                else
                    local dynamic_value = session:getVariable(input_value)
                    logger:debug(string.format("Header direct variable %s = %s", input_value, tostring(dynamic_value)))
                    headers = headers .. field_name .. ": " .. (dynamic_value or "")
                end
            elseif item.InputValueType == "S" then
                headers = headers .. field_name .. ": " .. input_value
            end

            logger:debug(string.format("Added header: %s", field_name))
        end
    end

    logger:info(string.format("Constructed headers: %s", headers))

    -- Build final API command
    logger:debug("Service URL: " .. service_url)
    local final_api = service_url .. " -s -w '+%{http_code}' "

    if content_type == "multipart/form-data" then
        headers = string.gsub(headers, '"', '')
        final_api = "curl -s -w '+%{http_code}' -X " .. method_type .. " -H '" .. headers .. "' " .. form_data .. " " ..
                        final_api

    elseif content_type == "audio/wav" then
        headers = string.gsub(headers, '"', '')
        final_api = "curl -s -w '+%{http_code}' -X " .. method_type .. " -H '" .. headers .. "' -H 'Content-Type: " ..
                        content_type .. "' " .. binary_data .. " " .. final_api

    else
        if content_type then
            final_api = final_api .. " -H \"Content-Type: " .. content_type .. "\""
        end

        if next(payload) ~= nil then
            local encoded_payload

            -- Log payload contents
            logger:info("Payload fields:")
            for k, v in pairs(payload) do
                logger:info(string.format("  %s = %s", tostring(k), tostring(v)))
            end

            if content_type == "application/x-www-form-urlencoded" then
                encoded_payload = urlencode_table(payload)
            elseif content_type == "application/json" then
                -- Encode payload directly as JSON (don't wrap in values format)
                local success, json_str = json_utils.encode(payload)
                if success then
                    encoded_payload = json_str
                else
                    logger:error("Failed to encode JSON payload")
                    encoded_payload = "{}"
                end
            else
                local success, json_str = json_utils.encode(payload)
                if success then
                    encoded_payload = json_str
                else
                    encoded_payload = "{}"
                end
            end

            encoded_payload = encoded_payload:gsub("\n", "")
            logger:info("Encoded payload: " .. encoded_payload)
            final_api = final_api .. " -X " .. method_type .. " -d '" .. encoded_payload .. "'"
        else
            logger:info("No payload to send")
        end

        if #headers > 0 then
            headers = string.gsub(headers, '"', '')
            final_api = final_api .. " -H \"" .. headers .. "\""
        end
    end

    logger:info("Final curl command: " .. final_api)
    return final_api
end

--------------------------------------------------------------------------------
-- Helper: Execute command and return result
--
-- @param command string - Command to execute
-- @return string - Command output
--------------------------------------------------------------------------------
local function execute_command(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

--------------------------------------------------------------------------------
-- Upload Incident Attachments
--
-- Uploads recorded audio files as attachments to the created incident.
-- Checks for caller name and incident details recordings in session variables.
--
-- @param incident_id string - The incident ID from the creation response
-- @param source_api_id number - The API ID that created the incident (11=AR, 12=EN)
-- @return void
--------------------------------------------------------------------------------
function M.upload_incident_attachments(incident_id, source_api_id)
    logger:info(string.format("Uploading attachments for incident: %s", incident_id))

    local session = session_manager.get_freeswitch_session()
    if not session or not session:ready() then
        logger:error("Session is not ready for attachment upload")
        return
    end

    -- Determine which language suffix to use based on source API
    local lang_suffix = (source_api_id == 11) and "Ar" or "En"

    -- List of possible recording variables to check
    local recording_vars = {
        "CallerName" .. lang_suffix,           -- Incident caller name
        "IncidentDetails" .. lang_suffix,      -- Incident description
        "CmplntCallerName" .. lang_suffix,     -- Complaint caller name
        "CmplntDetails" .. lang_suffix         -- Complaint details
    }

    local attachments_uploaded = 0

    -- Try to upload each recording if it exists
    for _, var_name in ipairs(recording_vars) do
        local recording_path = session:getVariable(var_name)

        if recording_path and recording_path ~= "" and file_utils.exists(recording_path) then
            logger:info(string.format("Uploading attachment from variable %s: %s", var_name, recording_path))

            -- Set the recording path and incident ID in session for the API
            session:setVariable("recording_file_path", recording_path)
            session:setVariable("incident_id_response", incident_id)

            -- Build the attachment upload API call
            local web_api_data = config.get_webapi_endpoints()
            if not web_api_data then
                logger:error("Web API configuration not found for attachment upload")
                return
            end

            -- Find attachment upload API (apiId 23)
            local attachment_api
            for _, api in pairs(web_api_data) do
                if api.apiId == 23 then
                    attachment_api = api
                    break
                end
            end

            if not attachment_api then
                logger:error("Attachment upload API (apiId 23) not found in configuration")
                return
            end

            -- Parse API input
            local api_input_data
            if type(attachment_api.apiInput) == "string" then
                local success, decoded = json_utils.decode(attachment_api.apiInput)
                if success then
                    api_input_data = decoded
                else
                    logger:error("Failed to decode attachment API input")
                    return
                end
            else
                api_input_data = attachment_api.apiInput or {}
            end

            -- Construct and execute the attachment upload API call
            local final_api = construct_api(
                attachment_api.methodType,
                attachment_api.inputMediaType,
                attachment_api.serviceURL,
                api_input_data
            )

            logger:info("Executing attachment upload: curl " .. final_api)
            local curl_cmd = "curl " .. final_api
            local api_response = execute_command(curl_cmd)

            logger:info("Attachment upload response: " .. tostring(api_response))

            -- Parse response code
            local response_code = tonumber(api_response:match("%+(%d+)$"))

            if response_code and response_code >= 200 and response_code < 300 then
                logger:info(string.format("Attachment uploaded successfully: %s", var_name))
                attachments_uploaded = attachments_uploaded + 1
            else
                logger:error(string.format("Failed to upload attachment %s, HTTP code: %s", var_name, tostring(response_code)))
            end
        else
            logger:debug(string.format("No recording found for variable: %s", var_name))
        end
    end

    if attachments_uploaded > 0 then
        logger:info(string.format("Successfully uploaded %d attachment(s) to incident %s", attachments_uploaded, incident_id))
    else
        logger:info("No attachments to upload")
    end
end

--------------------------------------------------------------------------------
-- Operation 111: API Call
--
-- Makes an API call based on configuration. Supports various content types
-- and handles response parsing.
--
-- Node Data Requirements:
-- - APIId: ID of the API configuration to use
--
-- @param node_data table - The IVR node configuration data
-- @return void
--------------------------------------------------------------------------------
function M.api_call(node_data)
    logger:info(string.format("Operation 111: API call for node %d", node_data.NodeId))

    local session = session_manager.get_freeswitch_session()

    if not session or not session:ready() then
        logger:error("Session is not ready")
        return
    end

    local api_id = node_data.APIId
    logger:info("API ID: " .. tostring(api_id))

    -- For incident creation APIs (11, 12), map indices to UUIDs first
    if api_id == 11 or api_id == 12 then
        logger:info("Incident creation API detected - mapping indices to UUIDs")
        map_indices_to_uuids(session)

        -- Log description variables for debugging
        local lang_suffix = (api_id == 11) and "Ar" or "En"
        local desc_text = session:getVariable("IncidentDetailsText" .. lang_suffix)
        local desc_audio = session:getVariable("IncidentDetails" .. lang_suffix)
        logger:info(string.format("Description values - Text: %s, Audio: %s",
            tostring(desc_text), tostring(desc_audio)))
    end

    -- Get API configuration
    local web_api_data = config.get_webapi_endpoints()

    if not web_api_data then
        logger:error("Web API configuration not found")
        call_flow.find_child_node_with_dtmf_input("F", node_data)
        return
    end

    local method_type, content_type, service_url, api_input_data, api_output

    for _, api in pairs(web_api_data) do
        if api.apiId == api_id then
            method_type = api.methodType
            content_type = api.inputMediaType
            service_url = api.serviceURL

            if type(api.apiInput) == "string" then
                local success, decoded = json_utils.decode(api.apiInput)
                if success then
                    api_input_data = decoded
                else
                    logger:error("Failed to decode apiInput: " .. tostring(decoded))
                    api_input_data = {}
                end
            else
                api_input_data = api.apiInput or {}
            end

            api_output = api.apiOutput
            break
        end
    end

    if not service_url then
        logger:error("API configuration not found for ID: " .. tostring(api_id))
        call_flow.find_child_node_with_dtmf_input("F", node_data)
        return
    end

    logger:info(string.format("API config - Method: %s, ContentType: %s, URL: %s", method_type, content_type,
        service_url))

    -- Construct and execute API call
    local final_api = construct_api(method_type, content_type, service_url, api_input_data)
    logger:debug("Final API command: " .. final_api)

    local input_keys = "F"

    if content_type == "application/json" then
        local curl_cmd = "curl " .. final_api
        logger:info("Executing curl: " .. curl_cmd)
        local api_response = execute_command(curl_cmd)

        logger:info("Raw API response: " .. tostring(api_response))

        -- Parse response code
        local response_code = tonumber(api_response:match("%+(%d+)$"))
        local response_body = api_response:gsub("%+%d+$", "")

        logger:info("HTTP response code: " .. tostring(response_code))
        logger:info("Response body: " .. tostring(response_body))

        if response_code and response_code >= 200 and response_code < 300 then
            local success, decoded_response = json_utils.decode(response_body)

            if success and decoded_response then
                logger:debug("Decoded response successfully")

                -- Process API output mapping
                local output_config
                if type(api_output) == "string" then
                    local out_success, out_decoded = json_utils.decode(api_output)
                    if out_success then
                        output_config = out_decoded
                    end
                elseif type(api_output) == "table" then
                    output_config = api_output
                end

                if output_config then
                    -- First pass: extract root-level fields
                    for _, key in ipairs(output_config) do
                        if key.ParentResultId == nil then
                            local field_name = key.ResultFieldName
                            local value = decoded_response[field_name]

                            if value ~= nil then
                                local value_str
                                if type(value) == "table" then
                                    local enc_success, enc_result = json_utils.encode(value)
                                    value_str = enc_success and enc_result or "{}"
                                else
                                    value_str = tostring(value)
                                end

                                session:setVariable(key.ResultFieldTag, value_str)
                                logger:debug(string.format("Set variable %s = %s", key.ResultFieldTag, value_str))
                            end
                        end
                    end

                    -- Second pass: extract nested fields using ParentResultId
                    for _, key in ipairs(output_config) do
                        if key.ParentResultId ~= nil then
                            -- Get parent data from response directly
                            local parent_data = decoded_response[key.ParentResultId]

                            if parent_data and type(parent_data) == "table" then
                                local value = parent_data[key.ResultFieldName]
                                if value ~= nil then
                                    local value_str = tostring(value)
                                    session:setVariable(key.ResultFieldTag, value_str)
                                    logger:debug(string.format("Set nested variable %s = %s (from %s.%s)",
                                        key.ResultFieldTag, value_str, key.ParentResultId, key.ResultFieldName))
                                end
                            end
                        end
                    end
                end

                -- Legacy: Check for recordID in response for backward compatibility
                if decoded_response.response and decoded_response.response.recordID then
                    local record_id = decoded_response.response.recordID
                    session:setVariable("incident_no_reponse", record_id)
                    logger:info("Set incident_no_reponse = " .. record_id)
                end

                -- Check for new API format (data.id for incident)
                if decoded_response.data and decoded_response.data.id then
                    session:setVariable("incident_id_response", decoded_response.data.id)
                    logger:info("Set incident_id_response = " .. decoded_response.data.id)
                end

                if decoded_response.data and decoded_response.data.ticket_number then
                    session:setVariable("ticket_number_response", decoded_response.data.ticket_number)
                    logger:info("Set ticket_number_response = " .. decoded_response.data.ticket_number)
                end

                -- Upload attachments after successful incident creation
                if (api_id == 11 or api_id == 12) and decoded_response.data and decoded_response.data.id then
                    logger:info("Incident created successfully, uploading attachments...")
                    M.upload_incident_attachments(decoded_response.data.id, api_id)
                end

                input_keys = "S"
            else
                logger:warning("Failed to decode JSON response")
            end
        else
            logger:error("API call failed with HTTP code: " .. tostring(response_code))
        end

    else
        -- Handle non-JSON content types (OAuth, etc.)
        local url = final_api:match("^(https://%S+)")
        local headers_list = {}

        for h in final_api:gmatch('%-H%s+"[^"]+"') do
            table.insert(headers_list, h)
        end

        local data = final_api:match('%-d%s*[\'"]([^\'"]+)[\'"]')

        local curl_cmd = 'curl -s -k -X POST '
        if data then
            curl_cmd = curl_cmd .. '-d "' .. data .. '" '
        end
        for _, h in ipairs(headers_list) do
            curl_cmd = curl_cmd .. h .. ' '
        end
        curl_cmd = curl_cmd .. (url or service_url)

        logger:debug("Formatted curl: " .. curl_cmd)

        local response = execute_command(curl_cmd)
        logger:debug("Response: " .. tostring(response))

        -- Parse response
        local body, status_code = response:match("^(.*)\n(%d%d%d)$")

        if not body then
            body = response
            status_code = 200
        end

        if body then
            body = body:gsub("^%s+", ""):gsub("%s+$", "")
        end
        status_code = tonumber(status_code)

        if status_code and status_code >= 200 and status_code < 300 then
            -- Process API output mapping
            if api_output and #api_output > 2 then
                local output_config = json_utils.decode(api_output)
                local decoded_response = json_utils.decode(body)

                if decoded_response and output_config then
                    for _, key in ipairs(output_config) do
                        if key.ParentResultId == nil then
                            local field_name = key.ResultFieldName

                            -- Handle token field name mapping
                            if field_name == "token" then
                                field_name = "access_token"
                            end

                            local value = decoded_response[field_name]
                            if value then
                                session:setVariable(key.ResultFieldTag, json_utils.encode(value))
                                logger:debug(string.format("Set variable %s = %s", key.ResultFieldTag,
                                    json_utils.encode(value)))
                            end
                        end
                    end

                    -- Process parent-child relationships
                    for _, key in ipairs(output_config) do
                        if key.ParentResultId ~= nil then
                            local parent_result = json_utils.decode(session:getVariable(key.ParentResultId))
                            if parent_result then
                                session:setVariable(key.ResultFieldTag, parent_result[key.ResultFieldName])
                            end
                        end
                    end
                end
            end

            input_keys = "S"
        end
    end

    call_flow.find_child_node_with_dtmf_input(input_keys, node_data)
end

--------------------------------------------------------------------------------
-- Operation 112: Simple API POST
--
-- Makes a simple API POST call using FreeSWITCH's built-in curl module.
--
-- Node Data Requirements:
-- - APIId: ID of the API configuration to use
--
-- @param node_data table - The IVR node configuration data
-- @return void
--------------------------------------------------------------------------------
function M.api_post(node_data)
    logger:info(string.format("Operation 112: API POST for node %d", node_data.NodeId))

    local session = session_manager.get_freeswitch_session()

    if not session or not session:ready() then
        logger:error("Session is not ready")
        return
    end

    local api_id = node_data.APIId

    -- Get API configuration
    local web_api_data = config.get_webapi_endpoints()

    if not web_api_data then
        logger:error("Web API configuration not found")
        call_flow.find_child_node_with_dtmf_input("F", node_data)
        return
    end

    local method_type, content_type, service_url, api_input_data

    for _, api in pairs(web_api_data) do
        if api.apiId == api_id then
            method_type = api.methodType
            content_type = api.inputMediaType
            service_url = api.serviceURL
            api_input_data = json_utils.decode(api.apiInput)
            break
        end
    end

    if not service_url then
        logger:error("API configuration not found for ID: " .. tostring(api_id))
        call_flow.find_child_node_with_dtmf_input("F", node_data)
        return
    end

    -- Construct and execute API call
    local final_api = construct_api(method_type, content_type, service_url, api_input_data)
    logger:debug("Final API: " .. final_api)

    -- Use FreeSWITCH curl module
    session:execute("curl", final_api)

    local curl_response_code = tonumber(session:getVariable("curl_response_code"))
    local curl_response = session:getVariable("curl_response_data")

    logger:info("Curl response code: " .. tostring(curl_response_code))

    if curl_response then
        logger:debug("Curl response data: " .. curl_response)
    end

    local input_keys = "F"

    if curl_response_code and curl_response_code >= 200 and curl_response_code < 300 then
        input_keys = "S"
    end

    call_flow.find_child_node_with_dtmf_input(input_keys, node_data)
end

return M
