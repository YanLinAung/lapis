local TEST_ENV = "test"
local normalize_headers
do
  local _obj_0 = require("lapis.spec.request")
  normalize_headers = _obj_0.normalize_headers
end
local ltn12 = require("ltn12")
local json = require("cjson")
local server_loaded = 0
local current_server = nil
local load_test_server
load_test_server = function()
  server_loaded = server_loaded + 1
  if not (server_loaded == 1) then
    return 
  end
  local attach_server
  do
    local _obj_0 = require("lapis.cmd.nginx")
    attach_server = _obj_0.attach_server
  end
  current_server = attach_server(TEST_ENV)
end
local close_test_server
close_test_server = function()
  server_loaded = server_loaded - 1
  if not (server_loaded == 0) then
    return 
  end
  current_server:detach()
  current_server = nil
end
local request
request = function(url, opts)
  if opts == nil then
    opts = { }
  end
  if not (server_loaded > 0) then
    error("The test server is not loaded!")
  end
  local http = require("socket.http")
  local server_port = require("lapis.config").get(TEST_ENV).port
  local headers = { }
  local method = opts.method
  local source
  do
    local data = opts.post or opts.data
    if data then
      if opts.post then
        method = method or "POST"
      end
      if type(data) == "table" then
        local encode_query_string
        do
          local _obj_0 = require("lapis.util")
          encode_query_string = _obj_0.encode_query_string
        end
        headers["Content-type"] = "application/x-www-form-urlencoded"
        data = encode_query_string(data)
      end
      headers["Content-length"] = #data
      source = ltn12.source.string(data)
    end
  end
  local buffer = { }
  local res, status
  res, status, headers = http.request({
    url = "http://127.0.0.1:" .. tostring(server_port) .. "/" .. tostring(url or ""),
    redirect = false,
    sink = ltn12.sink.table(buffer),
    headers = headers,
    method = method,
    source = source
  })
  return table.concat(buffer), status, normalize_headers(headers)
end
return {
  load_test_server = load_test_server,
  close_test_server = close_test_server,
  request = request,
  run_on_server = run_on_server
}