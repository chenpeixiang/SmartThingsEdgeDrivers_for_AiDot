local data_types = require "st.matter.data_types"
local TLVParser = require "st.matter.TLV.TLVParser"

local SetTemperature = {}

SetTemperature.NAME = "SetTemperature"
SetTemperature.ID = 0x0000
SetTemperature.field_defs = {
  {
    name = "target_temperature",
    field_id = 0,
    is_nullable = false,
    is_optional = true,
    data_type = require "st.matter.data_types.Int16",
  },
  {
    name = "target_temperature_level",
    field_id = 1,
    is_nullable = false,
    is_optional = true,
    data_type = require "st.matter.data_types.Uint8",
  },
}

function SetTemperature:build_test_command_response(device, endpoint_id, status)
  return self._cluster:build_test_command_response(
    device,
    endpoint_id,
    self._cluster.ID,
    self.ID,
    nil,
    status
  )
end

function SetTemperature:init(device, endpoint_id, target_temperature, target_temperature_level)
  local out = {}
  local args = {target_temperature, target_temperature_level}
  if #args > #self.field_defs then
    error(self.NAME .. " received too many arguments")
  end
  for i,v in ipairs(self.field_defs) do
    if v.is_optional and args[i] == nil then
      out[v.name] = nil
    elseif v.is_nullable and args[i] == nil then
      out[v.name] = data_types.validate_or_build_type(args[i], data_types.Null, v.name)
      out[v.name].field_id = v.field_id
    elseif not v.is_optional and args[i] == nil then
      out[v.name] = data_types.validate_or_build_type(v.default, v.data_type, v.name)
      out[v.name].field_id = v.field_id
    else
      out[v.name] = data_types.validate_or_build_type(args[i], v.data_type, v.name)
      out[v.name].field_id = v.field_id
    end
  end
  setmetatable(out, {
    __index = SetTemperature,
    __tostring = SetTemperature.pretty_print
  })
  return self._cluster:build_cluster_command(
    device,
    out,
    endpoint_id,
    self._cluster.ID,
    self.ID
  )
end

function SetTemperature:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

function SetTemperature:augment_type(base_type_obj)
  local elems = {}
  for _, v in ipairs(base_type_obj.elements) do
    for _, field_def in ipairs(self.field_defs) do
      if field_def.field_id == v.field_id and
         field_def.is_nullable and
         (v.value == nil and v.elements == nil) then
        elems[field_def.name] = data_types.validate_or_build_type(v, data_types.Null, field_def.field_name)
      elseif field_def.field_id == v.field_id and not
        (field_def.is_optional and v.value == nil) then
        elems[field_def.name] = data_types.validate_or_build_type(v, field_def.data_type, field_def.field_name)
        if field_def.element_type ~= nil then
          for i, e in ipairs(elems[field_def.name].elements) do
            elems[field_def.name].elements[i] = data_types.validate_or_build_type(e, field_def.element_type)
          end
        end
      end
    end
  end
  base_type_obj.elements = elems
end

function SetTemperature:deserialize(tlv_buf)
  local data = TLVParser.decode_tlv(tlv_buf)
  self:augment_type(data)
  return data
end

setmetatable(SetTemperature, {__call = SetTemperature.init})

return SetTemperature