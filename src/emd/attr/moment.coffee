EMD.attr.moment = (serialized_name, meta = {})->
  meta.convertFromData = (date)->
    moment(date) if date
  meta.convertToData = (moment)->
    moment.toDate() if moment
  EMD.attr(serialized_name, meta)

EMD.attr.duration = (serialized_name, meta = {})->
  unit = meta.unit ||= 'seconds'
  meta.convertFromData = (unit_value)->
    moment.duration(unit_value,
      unit) unless unit_value == undefined || unit_value == null
  meta.convertToData = (duration)->
    duration.as(unit) if duration
  EMD.attr serialized_name, meta
