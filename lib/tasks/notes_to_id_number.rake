namespace :migrations do
  task notes_to_id_number: :environment do
    rrs = ReportingRelationship.where.not(notes: [nil, ''])
    if rrs.pluck(:client_id).length != rrs.pluck(:client_id).uniq.length
      puts 'Warning conflicting RRS for a client'
      return
    end
    rrs.each do |rr|
      puts rr.notes
      ctrack = rr.notes.scan(/\d+/).first
      rr.client.update!(id_number: ctrack) if ctrack
      puts rr.client.id_number
    end
  end
end
