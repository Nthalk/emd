EMD.attr.moment = (serialized_name, meta = {})->
  meta.convertFrom = (date)->
    moment(date) if date
  meta.convertTo = (moment)->
    moment.toDate() if moment
  EMD.attr(serialized_name, meta)

EMD.attr.duration = (serialized_name, meta = {})->
  unit = meta.unit ||= 'seconds'
  meta.convertFrom = (unit_value)->
    moment.duration(unit_value,
      unit) unless unit_value == undefined || unit_value == null
  meta.convertTo = (duration)->
    duration.as(unit) if duration
  EMD.attr serialized_name, meta
