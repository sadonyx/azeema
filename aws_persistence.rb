require 'aws-sdk-s3'
require 'dotenv'
require 'mini_magick'
Dotenv.load

class AwsSession
  def initialize
    @s3 = Aws::S3::Client.new(
      region: 'us-west-1',
      credentials: Aws::Credentials.new(
        ENV['S3_ACCESS_ID'], ENV['S3_SECRET_KEY']
      )
    )
  end
  
  # BUCKET = @s3.bucket[ENV['S3_BUCKET']]

  def put_profile_picture(path, image_name)
    format_profile_picture(path)

    File.open(path, 'r') do |file|
      @s3.put_object(
        bucket: 'azeema',
        key: image_name,
        body: file
      )
    end
  end

  def put_event_picture(path, image_name)
    format_event_picture(path, image_name)

    File.open(path, 'r') do |file|
      @s3.put_object(
        bucket: 'azeema',
        key: image_name,
        body: file
      )
    end
  end

  def format_event_picture(path, image_name)
    image = MiniMagick::Image.new(path)
    width = image.width.to_i
    height = image.height.to_i

    if is_a_square?(width, height)
      image.resize "500x500"
    else
      image.resize_to_fill(500, 500)
    end
  end

  private

  def format_profile_picture(path)
    image = MiniMagick::Image.new(path)
    width = image.width.to_i
    height = image.height.to_i

    if is_a_square?(width, height)
      image.resize "100x100"
    else
      image.crop "100x100+#{width/2 - 100}+#{height/2 - 100}"
    end
  end

  def is_a_square?(width, height)
    (0..10).include? (width - height).abs
  end
end