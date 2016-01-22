namespace :valhal do
  desc 'Add default values to rightsMetadataStream'
  task set_default_rights: :environment do
      Work.all.collect {|t| add_default_rights(t)}
      Instance.all.collect {|t| add_default_rights(t)}
      # Trykforlaeg.all.collect {|t| add_default_rights(t)}
      ContentFile.all.collect {|t| add_default_rights(t)}
      Authority::Base.all.collect {|t| add_default_rights(t)}
  end

  desc 'Load pre-configured ControlledLists'
  task load_controlled_lists: :environment do
    Administration::ControlledList.delete_all
    Administration::ListEntry.delete_all
    lists = YAML.load_file(Rails.root.join('config', 'controlled_lists.yml'))
    lists.each_value do |val|
      current = Administration::ControlledList.create(name: val['name'])
      if val.has_key?('entries')
        val['entries'].each do |name, label|
          Administration::ListEntry.create(name: name, label: label, controlled_list: current)
        end
      end
    end
  end

  desc 'Reindex all activefedora objects'
  task reindex: :environment do
    puts "deleting all documents from Solr"
    system "curl -H 'Content-Type: text/xml' http://localhost:8983/solr/update?commit=true --data-binary '<delete><query>*:*</query></delete>'"
    puts "updating index"
    ActiveFedora::Base.reindex_everything
  end

  desc 'Set default rights on Person Objects'
  task set_default_rights_person: :environment do
    Authority::Person.all.each{|p| add_default_rights(p)}
  end

  desc 'Set default rights on Person Objects'
  task set_default_rights_organization: :environment do
    Authority::Organization.all.each{|p| add_default_rights(p)}
  end

  private

  def add_default_rights(obj)
    puts "Setting rights on #{obj.class} #{obj.id}"
    begin
      obj.edit_groups = ['Chronos-Admin']
      obj.save
    rescue => e
      puts "Error setting rights on #{obj.class} #{obj.id} #{e}"
    end
  end


  desc 'Configure solr by adding an extra public core for development purposes'
  task :configure_solr do
    # Create directory in jetty by copying over dev dir
    solr_dir = Rails.root.join('jetty', 'solr')
    dev_core = solr_dir.join('development-core')
    public_core = solr_dir.join('development-public')
    FileUtils.copy_entry(dev_core, public_core)
    data_dir = public_core.join('data')

    # Delete dev data files
    index_files = Dir.glob(File.join(data_dir, 'index', '*'))
    spell_files = Dir.glob(File.join(data_dir, 'spell', '*'))
    tlog_files = Dir.glob(File.join(data_dir, 'tlog', '*'))
    FileUtils.rm index_files
    FileUtils.rm spell_files
    FileUtils.rm tlog_files

    # Update solr.xml
    solr_conf = Rails.root.join('solr_conf', 'solr.xml')
    FileUtils.cp solr_conf, solr_dir
  end

  desc 'Clean data WARNING: will remove all data from you repository'
  task clean: :environment do
    raise "You do not want to delete all production data" if Rails.env == 'production'
    delete_all_objects
  end

  private
  def delete_all_objects
    ContentFile.find_each(&:delete)
    Instance.find_each(&:delete)
    Relator.find_each(&:delete)
    Authority::Thing.find_each(&:delete)
    Title.find_each(&:delete)
    Work.find_each(&:delete)
    Administration::Activity.find_each(&:delete)
    Hydra::AccessControls::Permission.find_each(&:delete)

    # Try to nuke the rest if something is left
    ActiveFedora::Base.find_each(&:delete)
  end
end
