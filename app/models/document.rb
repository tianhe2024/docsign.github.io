# == Schema Information
#
# Table name: documents
#
#  id          :uuid             not null, primary key
#  description :text
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "aws-sdk-s3"

class Document < ApplicationRecord
  ACCEPTABLE_TYPES = ["application/pdf", "image/png", "image/jpg", "image/jpeg", "image/jpg", "image/svg+xml"]

  # attached: true,
  validates :file,
            content_type: {
              in: ACCEPTABLE_TYPES,
              message: "is not an acceptable type",
            },
            size: {
              less_than: 20.megabytes,
              message: "is not given between size",
            }

  # validates :editor_ids, presence: true

  # ActiveStorage association
  has_one_attached :file

  # ActiveRecord associations
  has_many :content_fields,
           class_name: :ContentField,
           dependent: :destroy
  has_many :document_editors
  has_many :editors,
           through: :document_editors,
           source: :user

  def blob
    file.blob if file && file.blob
  end

  def gen_presigned_url(expires_in = 900)
    blob.service_url(expires_in: expires_in)
  end

  def owner
    d_owner = document_editor_owner
    d_owner.user unless d_owner.nil?
  end

  def owner=(user)
    de = document_editor_owner
    if de
      return user if de == user
      de.set_owner(false)
    end

    document_editors.find_by(user_id: user.id).set_owner(true)
  end

  private

  def document_editor_owner
    document_editors.find_by(is_owner: true)
  end

  def aws_client
    @s3 = Aws::S3::Resource.new(region: Rails.application.credentials.aws.region)
  end

  def bucket
    client = @s3 || aws_client
    if Rails.env.production?
      return client.bucket(Rails.application.credentials.aws.prod.bucket)
    else
      return client.bucket(Rails.application.credentials.aws.dev.bucket)
    end
  end
end