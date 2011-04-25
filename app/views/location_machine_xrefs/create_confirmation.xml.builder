xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.msg "\nadd successful\n"
  xml.id "\n#{@lmx.machine_id.to_s}\n"
end
