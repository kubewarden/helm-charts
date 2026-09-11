-- Consts
local EVT_MONITOR = "monitor"
local EVT_PROTECT = "protect"
local EVT_LEARN = "learn"
local DIRECTION_INBOUND = "inbound"
local MSG_LEARN = "connection complete"
-- Monitor (dry-run) rejection messages from ztunnel state logs. These mirror the
-- protect-mode messages below but are prefixed `dry-run:` and use the present
-- tense ("match" vs "matched"). Allowed dry-run flows (e.g. "dry-run: allow
-- policy match", "dry-run: no allow policies, allow") are NOT rejections and must
-- not be matched here, so we match the two rejection messages exactly rather than
-- by a bare `^dry-run:` prefix.
local MSG_MONITOR_DENY = "dry-run: deny policy match"
local MSG_MONITOR_ALLOW_MISS = "dry-run: no allow policies match"
-- Enforcement (protect mode) rejection messages from ztunnel state logs
local MSG_VIOLATION_DENY = "deny policy match"
local MSG_VIOLATION_ALLOW_MISS = "no allow policies matched"

local function has_empty_field(record, key)
  local value = record[key]
  return value == nil or tostring(value) == ""
end

local function extract_port(address)
  if address == nil then
    return ""
  end
  local port = tostring(address):match(":(%d+)$")
  if port == nil then
    return ""
  end
  return port
end

-- Monitor dry-run and protect enforcement events share the same plumbing and
-- attribution rules: they only differ in the `evt.type` tag.
local function to_policy_event(timestamp, record, evt_type)
  local proxy = record["proxy"] or {}
  local inbound = record["inbound"] or {}

  local out = {}
  out["evt.type"] = evt_type
  -- `namespace/name` format
  -- e.g. "default/http-server-7bbf596dd9-8gs65"
  out["dst.namespaced_name"] = proxy["wl"] or ""
  -- `namespace/name` format if present, otherwise ""
  -- e.g. "default/deny-http-server-monitor"
  -- ALLOW-miss rejections have no denying policy, so the name is left empty
  out["policy"] = record["policy"] or ""
  -- `ip:port` format
  out["src.addr"] = inbound["peer"] or ""
  out["message"] = record["message"] or ""
  return 1, timestamp, out
end

local function to_learn_event(timestamp, record)
  -- We are only interested in inbound connections
  if record["direction"] ~= DIRECTION_INBOUND then
    return -1, timestamp, record
  end

  -- Skip learning when one endpoint is outside the mesh.
  -- These logs do not include both identities.
  if has_empty_field(record, "src.identity") or has_empty_field(record, "dst.identity") then
    return -1, timestamp, record
  end

  local out = {}
  out["evt.type"] = EVT_LEARN
  out["dst.name"] = record["dst.workload"]
  out["dst.namespace"] = record["dst.namespace"]
  out["dst.port"] = extract_port(record["dst.hbone_addr"])
  out["src.identity"] = record["src.identity"]
  -- Original ztunnel message: Fluent Bit Logs_Body_Key $message maps this to
  -- OTLP LogRecord.body.
  out["message"] = record["message"] or ""
  return 1, timestamp, out
end

function to_otel(tag, timestamp, record)
  local message = record["message"]

  -- Monitor dry-run rejections: mirror the protect-mode branch below, but for
  -- the `dry-run:`-prefixed messages. Allowed dry-run flows are not rejections
  -- and are intentionally excluded.
  if message == MSG_MONITOR_DENY or message == MSG_MONITOR_ALLOW_MISS then
    return to_policy_event(timestamp, record, EVT_MONITOR)
  end

  -- Enforcement rejections: an explicit DENY match carries the policy name,
  -- an ALLOW-miss is recorded without a policy name. Allowed flows
  -- ("no allow policies, allow", "allow policy match") are not violations.
  if message == MSG_VIOLATION_DENY or message == MSG_VIOLATION_ALLOW_MISS then
    return to_policy_event(timestamp, record, EVT_PROTECT)
  end

  if message == MSG_LEARN then
    return to_learn_event(timestamp, record)
  end
  return -1, timestamp, record
end
