require 'open-uri'
require 'fog'
require 'erb'

STDOUT.sync=true

class BuildUbuntuAmi
  USER_DATA = File.read(File.join(File.dirname(__FILE__),'..','data','user_data.sh.erb'))

  attr_accessor :region, :flavor, :brand, :size, :codename, :key_name, :group,
    :custom_user_script, :now, :server, :volume, :snapshot, :arch,
    :canonical_ami, :kernel, :virtualization

  def self.default_options
    {
      :region   => 'us-east-1',
      :flavor   => 'm1.small',
      :brand    => 'My',
      :size     => 20,
      :codename => 'precise',
      :key_name => 'default',
      :group    => 'default',
      :arch     => 'amd64',
      :kernel   => nil,
      :virtualization => 'paravirtual'
    }
  end

  def initialize(opts={})
    opts = self.class.default_options.merge(opts)
    puts "Configuration:"
    (self.class.default_options.keys - [:kernel]).each do |attr|
      puts "  #{attr}: #{opts[attr]}"
      self.send("#{attr}=", opts[attr])
    end
    self.custom_user_script = opts[:custom_user_script]

    find_canonical_ubuntu_ami
    puts "  canonical ami: #{canonical_ami}"
    puts "  kernel: #{kernel}"

    @now = Time.now.strftime('%Y%m%d-%H%M')
    puts "  description: #{description}"
  end

  # Return the Ubuntu AMI with the architecture for +flavor+
  def find_canonical_ubuntu_ami
    url = "http://uec-images.ubuntu.com/query/#{codename}/server/released.current.txt"
    data = open(url).read.split("\n").map{|l| l.split}.detect do |ary|
      ary[4] == 'ebs' &&
        ary[5] == arch &&
        ary[6] == region &&
        ary.last == virtualization
    end

    self.canonical_ami = data[7]
    self.kernel ||= data[8]
  end

  def image_arch
    case arch
    when 'amd64'
      'x86_64'
    else
      arch
    end
  end

  def description
    "#{brand}-#{codename}-#{arch}-#{now}"
  end

  def ebs_device
    '/dev/xvdi'
  end

  def root_device
    '/dev/sda1'
  end

  def block_device_mapping
    [{ "DeviceName" => root_device, "SnapshotId" => snapshot.id, "VolumeSize" => size, "DeleteOnTermination" => true }]
  end

  def image_name
    "#{codename}-server-cloudimg-#{arch}"
  end

  def image_url
    "http://uec-images.ubuntu.com/#{codename}/current/#{image_name}.tar.gz"
  end

  def fog
    @fog ||= Fog::Compute.new(:provider => 'AWS', :region => region)
  end

  def launch_server!
    puts "Launching server..."
    self.server = fog.servers.create({
      :flavor_id => flavor,
      :image_id => canonical_ami,
      :groups => [group],
      :key_name => key_name,
      :user_data => user_data
    })
    server.wait_for { ready? }
    puts "Launched #{server.id}; #{server.dns_name}; waiting for it to be available."
  end

  def launch_volume!
    self.volume = server.volumes.create(:size => size, :device => ebs_device)
    puts "Attaching volume #{volume.id}"
    volume.wait_for { state == 'in-use'|| state == 'attached' }
  end

  def snapshot_description
    "#{description} root volume"
  end

  def take_snapshot!
    puts "Waiting for volume to detach..."
    volume.wait_for { state == 'available' }
    puts "Taking snapshot #{snapshot_description} from #{volume.id}"
    self.snapshot = volume.snapshots.create(:description => snapshot_description)
    puts "Creating snapshot #{snapshot.id}"
    snapshot.wait_for { ready? }
  end

  def user_data
    @user_data ||= USER_DATA
    ERB.new(@user_data).result(binding)
  end

  def cleanup!
    stack.destroy
  end

  def build!
    launch_server!
    launch_volume!

    puts "waiting for user_data to complete and server to shut down..."
    puts "Follow along by running:"
    puts "  ssh -l #{server.username} #{server.dns_name} 'tail -f /var/log/user-data.log'"
    server.wait_for(60*60*24*7) { state == 'stopped' || state == 'stopping' }

    puts "Detaching volume"
    volume.server = nil

    take_snapshot!

    # Register AMI
    res = fog.register_image(description, description, root_device, block_device_mapping, 'KernelId' => kernel, 'Architecture' => image_arch)
    puts "Registered imageId #{res.body['imageId']}"

    cleanup!

  end
end
